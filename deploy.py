import os
import sys
import argparse
from pathlib import Path
from fabric_cicd import deploy_with_config, change_log_level
from azure.identity import AzureCliCredential
# Ensure real-time logs in Azure DevOps
sys.stdout.reconfigure(line_buffering=True, write_through=True)
sys.stderr.reconfigure(line_buffering=True, write_through=True)

def main():
    # FAIL-FAST: Ensure the pipeline passed the environment name
    target_env = os.environ.get("TARGET_ENV")
    if not target_env:
        print("❌ ERROR: 'TARGET_ENV' environment variable is missing.")
        print("Make sure 'export TARGET_ENV=test' is in your pipeline YAML.")
        sys.exit(1)
    print(f"🚀 Deployment Target: {target_env}")
    # Set logging for visibility
    change_log_level("DEBUG")
    try:
        # Use Azure CLI credential to authenticate
        credential = AzureCliCredential()

        # deploy_with_config looks at your config.yml 
        # It uses '.' as the repo directory (where your .Notebook folders are)
        deploy_with_config(
            config_file_path="config.yml",
            environment=target_env,
            token_credential=credential,
        )
        print(f"\n✅ SUCCESS: Items deployed to {target_env} workspace.")
        
    except Exception as e:
        print(f"\n❌ DEPLOYMENT FAILED")
        print(f"Detail: {str(e)}")
        # Ensure the pipeline fails if the script fails
        sys.exit(1)
if __name__ == "__main__":
    main()