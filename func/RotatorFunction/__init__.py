from azure.identity.aio import DefaultAzureCredential, ManagedIdentityCredential
from core.services.rotator import RotatorService
import azure.functions as func
import datetime
import logging
import os

async def main(timer: func.TimerRequest) -> None:
    logging.info(f"RotatorFunction function executed at: {datetime.datetime.now()}")
    rotator = None
    try:
        managed_identity_client_id = os.environ.get("MANAGED_IDENTITY_CLIENT_ID")
        if not managed_identity_client_id:
            raise ValueError(f"Missing required environment variable: MANAGED_IDENTITY_CLIENT_ID")
        
        credential = ManagedIdentityCredential(client_id=managed_identity_client_id)
        
        if not credential:
            credential = DefaultAzureCredential()

        vault_url = os.environ["KEY_VAULT_URL"]
        rotation_interval = int(os.environ["ROTATION_INTERVAL"])

        if not all([credential, vault_url, rotation_interval]):
            raise ValueError(f"Missing required environment variables: KEY_VAULT_URL, ROTATION_INTERVAL, DefaultAzureCredential")

        if type(rotation_interval) != int:
            raise ValueError(f"Invalid value for ROTATION_INTERVAL. Expected an integer.")
        
        try:
            run_cleanup = bool(int(os.environ.get("RUN_CLEANUP", "0")))
        except ValueError:
            raise ValueError(f"Invalid value for RUN_CLEANUP. Expected a 0 or 1.")  
        
        rotator = RotatorService(vault_url=vault_url, credential=credential, key_rotation_interval_in_days=rotation_interval)

        app_registrations = await rotator.find_expiring_app_registratons()
        await rotator.rotate_all_expiring_app_registrations(app_registrations)

        if run_cleanup:
            await rotator.cleanup_old_password_credentials(app_registrations)

    except Exception as e:
        logging.error(f"An error occurred: {e}")

    finally:
        if rotator:
            if rotator.client:
                await rotator.client.close()
            if rotator.credential:
                await rotator.credential.close()

    logging.info("RotatorFunction function completed.")