from azure.identity.aio import ClientSecretCredential, DefaultAzureCredential, ManagedIdentityCredential
from msgraph.generated.models.password_credential import PasswordCredential
from msgraph.generated.models.application import Application
from azure.keyvault.secrets.aio import SecretClient
from typing import Union
import datetime as dt



class KeyVaultService:
    def __init__(self, vault_url: str, credential: Union[ClientSecretCredential, DefaultAzureCredential, ManagedIdentityCredential] = None):
        self.credential = credential
        self.client = SecretClient(vault_url=vault_url, credential=self.credential)
    
    async def get_all_secrets(self) -> dict:
        secret_names = [s.name async for s in self.client.list_properties_of_secrets()]
        secrets_array = {}
        
        for name in secret_names:
            secret = await self.client.get_secret(name)
            secrets_array[name] = secret.value

        return secrets_array
    
    async def update_secrets(self, application: Application, password_credential: PasswordCredential, expiration_date: dt.datetime):
        try:
            client = SecretClient(vault_url=self.client.vault_url, credential=self.credential)
            
            app_secret_secret_name = f"{application.display_name}-secret"
            app_secret_secret_value = password_credential.secret_text
            app_secret_secret = await client.set_secret(name=app_secret_secret_name, 
                                                        value=app_secret_secret_value, 
                                                        expires_on=expiration_date,
                                                        tags={
                                                            "app_name": application.display_name,
                                                            "app_id": application.app_id
                                                        })

            return app_secret_secret
        
        finally:
            if client:
                await client.close()



