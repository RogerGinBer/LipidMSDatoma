# Please, do NOT modify this file.
import subprocess
import os
import time

if __name__ == "__main__":
    # Set up necessary environment variables

    extra_index_url = os.getenv('PIP_EXTRA_INDEX_URL')
    bash_command = """
    pip install --extra-index-url {extra_index_url} datoma-jobrunner
    """

    success = False 
    attempt = 0
    while not success: 
        result = subprocess.run(["/bin/bash", "-c", bash_command]) 
        if result.returncode == 0: 
            success = True 
            print("\ndatoma-jobrunner installed!")
        elif attempt == 5: 
            print("\nFailed to install datoma-jobrunner. Please check your internet connection and try again.")
            exit(1)
        else: 
            print("\nRetrying jobrunner install...\n")
            attempt += 1 
            backoff_time = 2 ** attempt 
            print(f"Waiting for {backoff_time} seconds before retrying...\n") 
            time.sleep(backoff_time)
