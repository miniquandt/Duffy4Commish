import os
import requests
import urllib.request
import bz2
import concurrent.futures

# Function to download a file from a URL into the "downloads" folder
def download_file(url, output_folder):
    try:
        file_name = url.split("/")[-1].replace(":", "_")
        output_path = os.path.join(output_folder, file_name)
        
        # Download the file
        urllib.request.urlretrieve(url, output_path)
        
        # Check if the file is a .bz2 archive and decompress it
        if file_name.endswith(".bz2"):
            with open(output_path, 'rb') as f_in, open(output_path[:-4], 'wb') as f_out:
                decompressor = bz2.BZ2Decompressor()
                for data in iter(lambda: f_in.read(100 * 1024), b''):
                    f_out.write(decompressor.decompress(data))
            
            # Remove the .bz2 file
            os.remove(output_path)
        
        print(f"File downloaded to {output_path}")
    except Exception as e:
        print(f"Error downloading or decompressing file: {e}")

# Function to read all URLs from keys.txt
def get_all_urls_from_keys_file(keys_file):
    try:
        urls = []

        
        if(os.getcwd().split("\\")[-1] == "Duffy4Commish"):
            keys_file = "DownloadRiotData\\" + keys_file
        if(os.getcwd().split("/")[-1] == "Duffy4Commish"):
            keys_file = "DownloadRiotData/" + keys_file

        with open(keys_file, "r") as file:
            for line in file:
                url = line.strip()
                urls.append(url)

        return urls
    except FileNotFoundError:
        print(f"File not found: {keys_file}")
        return []

if __name__ == "__main__":
    keys_file = "keys.txt"  # Replace with the path to your keys.txt file
    download_folder = "esports-data"  # Name of the folder to save downloaded files

    # if in the DownloadRiotData folder, attempt to put files in one directory up
    if(os.getcwd().split("\\")[-1] == "DownloadRiotData"):
        download_folder = "..\\"+download_folder
    if(os.getcwd().split("/")[-1] == "DownloadRiotData"):
        download_folder = "../"+download_folder

    print(download_folder)
    # Create the "downloads" folder if it doesn't exist
    os.makedirs(download_folder, exist_ok=True)
    urls_to_download = get_all_urls_from_keys_file(keys_file)

    with concurrent.futures.ThreadPoolExecutor() as executor:
        # Download files in parallel
        futures = []
        for url in urls_to_download:
            future = executor.submit(download_file, url, download_folder)
            futures.append(future)

        # Wait for all download tasks to complete
        concurrent.futures.wait(futures)
