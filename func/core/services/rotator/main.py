from msgraph.generated.applications.item.add_password.add_password_post_request_body import AddPasswordPostRequestBody 
from msgraph.generated.applications.item.remove_password.remove_password_post_request_body import RemovePasswordPostRequestBody
from azure.identity.aio import ClientSecretCredential, DefaultAzureCredential, ManagedIdentityCredential
from msgraph.generated.models.password_credential import PasswordCredential
from core.services.kv import KeyVaultService
from msgraph import GraphServiceClient
from typing import Union
import datetime as dt
import pandas as pd
import asyncio
import logging

class RotatorService(KeyVaultService):
    def __init__(self, vault_url: str, credential: Union[ClientSecretCredential, DefaultAzureCredential, ManagedIdentityCredential], key_rotation_interval_in_days: int):
        super().__init__(vault_url, credential)
        self.graph = GraphServiceClient(credential)
        self.key_rotation_interval_in_days = key_rotation_interval_in_days
        self.credential = credential

    def _find_max_end_date(self, end_dates: list) -> dt.datetime:

        if end_dates == []:

            return None
        
        utc_end_dates = [end_date.astimezone(dt.timezone.utc) for end_date in end_dates]

        return max(utc_end_dates)
        
    async def _get_app_ids(self) -> list:
        application_ids = []

        try:

            application_response = await self.graph.applications.get()
            application_ids.extend([app.app_id for app in application_response.value])


            next_link = application_response.odata_next_link

            while next_link:

                application_response = await self.graph.applications.with_url(next_link).get()
                application_ids.extend([app.app_id for app in application_response.value])

                next_link = application_response.odata_next_link

        except Exception as e:
            logging.info(f"An error occurred while fetching app IDs: {e}")
            

        return application_ids
        
    async def _get_app_password_credential_end_dates(self, app_id: str) -> list:

        graph = GraphServiceClient(self.credential)

        application = await graph.applications_with_app_id(app_id).get()
        password_credentials = application.password_credentials
        end_dates = [cred.end_date_time for cred in password_credentials]

        return end_dates

    
    async def _insert_password_credential_end_dates(self, app_registrations: pd.DataFrame) -> pd.DataFrame:
        app_registrations = app_registrations.copy()
        app_ids = app_registrations['secret_value']

        coroutines = [self._get_app_password_credential_end_dates(app_id) for app_id in app_ids]

        password_credential_end_dates = await asyncio.gather(*coroutines)

        app_registrations['password_credential_end_dates'] = password_credential_end_dates

        return app_registrations

    async def find_expiring_app_registratons(self) -> pd.DataFrame:
        
        secrets, app_ids = await asyncio.gather(
            self.get_all_secrets(), 
            self._get_app_ids()
            )
        

        df = pd.DataFrame(list(secrets.items()), columns=['secret_name', 'secret_value'])
        
        app_registrations = df[df['secret_value'].isin(app_ids)].copy()

        app_registrations = await self._insert_password_credential_end_dates(app_registrations)
        app_registrations['latest_end_date'] = app_registrations['password_credential_end_dates'].apply(self._find_max_end_date)

        now = dt.datetime.now(dt.timezone.utc)
        rotation_threshold = now + dt.timedelta(days=self.key_rotation_interval_in_days)

        app_registrations['needs_rotation'] = app_registrations['latest_end_date'].isna() | (app_registrations['latest_end_date'] < rotation_threshold)
  
        app_registrations_to_rotate = app_registrations[app_registrations['needs_rotation']]

        return app_registrations_to_rotate

    async def _rotate_app_registration(self, app_id: str):
        graph = GraphServiceClient(self.credential)
        
        application = await graph.applications_with_app_id(app_id).get()
        
        now = dt.datetime.now(dt.timezone.utc)
        expiration = now + dt.timedelta(days=(self.key_rotation_interval_in_days * 2))
        
        request_body = AddPasswordPostRequestBody(
            password_credential=PasswordCredential(
                display_name=f"rotated-{now.isoformat()}",
                end_date_time=expiration
                )
            )

        password_credential = await graph.applications.by_application_id(application.id).add_password.post(request_body)
        await self.update_secrets(application, password_credential, expiration_date=expiration)
        logging.info(f"Rotated app registration for {app_id}")
    
    async def rotate_all_expiring_app_registrations(self, app_registrations: pd.DataFrame):
        coroutines = [
            self._rotate_app_registration(row['secret_value']) 
            for index, row in app_registrations.iterrows()
        ]
        
        await asyncio.gather(*coroutines)

    async def cleanup_old_password_credentials(self, app_registrations: pd.DataFrame):
        logging.info("Cleaning up old password credentials")
        coroutines = [
            self._cleanup_old_password_credential(row['secret_value'])
            for index, row in app_registrations.iterrows()
        ]

        await asyncio.gather(*coroutines)

    async def _cleanup_old_password_credential(self, app_id: str):
        graph = GraphServiceClient(self.credential)

        application = await graph.applications_with_app_id(app_id).get()
        password_credentials = application.password_credentials

        if not password_credentials or len(password_credentials) <= 1:
            logging.info(f"App registration {app_id} has no password credentials to cleanup")
            return
        
        max_end_date = max(
            (cred.end_date_time for cred in password_credentials if cred.end_date_time),
            default=None
        )

        if max_end_date is None:
            logging.info(f"App registration {app_id} has no password credentials to cleanup")
            return

        credentials_to_keep = [
            cred for cred in password_credentials if cred.end_date_time == max_end_date
        ]

        credentials_to_delete = [
            cred for cred in password_credentials if cred not in credentials_to_keep
        ]

        if not credentials_to_delete:
            logging.info(f"App registration {app_id} has no password credentials to cleanup")
            return
        
        coroutines = [
            self._delete_password_credential(object_id=application.id, key_id=cred.key_id, app_id=application.app_id)
            for cred in credentials_to_delete
        ]

        await asyncio.gather(*coroutines)

    async def _delete_password_credential(self, object_id: str, key_id: str, app_id: str):
        graph = GraphServiceClient(self.credential)

        request_body = RemovePasswordPostRequestBody(
            key_id=key_id
        )

        await graph.applications.by_application_id(object_id).remove_password.post(request_body)
        logging.info(f"Removed password credential {key_id} from app registration {app_id}")


