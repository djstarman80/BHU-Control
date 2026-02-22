import os
import requests
from github import Github
from typing import Optional, List, Dict, Any

class GitHubAPI:
    def __init__(self, token: Optional[str] = None, repo: str = "djstarman80/BHU-Control"):
        self.token = token or os.environ.get("GITHUB_TOKEN")
        self.repo = repo
        self.owner, self.repo_name = repo.split("/")
        
    def get_workflow_runs(self, workflow_id: str = "deploy.yml") -> List[Dict[str, Any]]:
        url = f"https://api.github.com/repos/{self.repo}/actions/workflows/{workflow_id}/runs"
        headers = {
            "Authorization": f"token {self.token}",
            "Accept": "application/vnd.github.v3+json"
        }
        response = requests.get(url, headers=headers)
        if response.status_code == 200:
            return response.json().get("workflow_runs", [])
        return []
    
    def get_latest_workflow_run(self, workflow_id: str = "deploy.yml") -> Optional[Dict[str, Any]]:
        runs = self.get_workflow_runs(workflow_id)
        return runs[0] if runs else None
    
    def get_workflow_run_status(self, run_id: int) -> Dict[str, Any]:
        url = f"https://api.github.com/repos/{self.repo}/actions/runs/{run_id}"
        headers = {
            "Authorization": f"token {self.token}",
            "Accept": "application/vnd.github.v3+json"
        }
        response = requests.get(url, headers=headers)
        if response.status_code == 200:
            return response.json()
        return {}
    
    def get_jobs(self, run_id: int) -> List[Dict[str, Any]]:
        url = f"https://api.github.com/repos/{self.repo}/actions/runs/{run_id}/jobs"
        headers = {
            "Authorization": f"token {self.token}",
            "Accept": "application/vnd.github.v3+json"
        }
        response = requests.get(url, headers=headers)
        if response.status_code == 200:
            return response.json().get("jobs", [])
        return []
    
    def get_artifacts(self, run_id: int) -> List[Dict[str, Any]]:
        url = f"https://api.github.com/repos/{self.repo}/actions/runs/{run_id}/artifacts"
        headers = {
            "Authorization": f"token {self.token}",
            "Accept": "application/vnd.github.v3+json"
        }
        response = requests.get(url, headers=headers)
        if response.status_code == 200:
            return response.json().get("artifacts", [])
        return []
    
    def download_artifact(self, artifact_id: int, output_path: str) -> bool:
        url = f"https://api.github.com/repos/{self.repo}/actions/artifacts/{artifact_id}/zip"
        headers = {
            "Authorization": f"token {self.token}",
            "Accept": "application/vnd.github.v3+json"
        }
        response = requests.get(url, headers=headers, stream=True)
        if response.status_code == 200:
            with open(output_path, "wb") as f:
                for chunk in response.iter_content(chunk_size=8192):
                    f.write(chunk)
            return True
        return False
    
    def create_release(self, tag_name: str, name: str, body: str = "", prerelease: bool = False) -> Optional[Dict[str, Any]]:
        url = f"https://api.github.com/repos/{self.repo}/releases"
        headers = {
            "Authorization": f"token {self.token}",
            "Accept": "application/vnd.github.v3+json"
        }
        data = {
            "tag_name": tag_name,
            "name": name,
            "body": body,
            "prerelease": prerelease
        }
        response = requests.post(url, headers=headers, json=data)
        if response.status_code in [200, 201]:
            return response.json()
        return None
    
    def upload_release_asset(self, release_id: int, name: str, file_path: str) -> bool:
        url = f"https://api.github.com/repos/{self.repo}/releases/{release_id}/assets"
        headers = {
            "Authorization": f"token {self.token}",
            "Content-Type": "application/octet-stream"
        }
        
        with open(file_path, "rb") as f:
            data = f.read()
        
        params = {"name": name}
        response = requests.post(url, headers=headers, params=params, data=data)
        return response.status_code in [200, 201]
    
    def get_latest_release(self) -> Optional[Dict[str, Any]]:
        url = f"https://api.github.com/repos/{self.repo}/releases/latest"
        headers = {
            "Authorization": f"token {self.token}",
            "Accept": "application/vnd.github.v3+json"
        }
        response = requests.get(url, headers=headers)
        if response.status_code == 200:
            return response.json()
        return None
    
    def get_release_by_tag(self, tag: str) -> Optional[Dict[str, Any]]:
        url = f"https://api.github.com/repos/{self.repo}/releases/tags/{tag}"
        headers = {
            "Authorization": f"token {self.token}",
            "Accept": "application/vnd.github.v3+json"
        }
        response = requests.get(url, headers=headers)
        if response.status_code == 200:
            return response.json()
        return None
    
    def get_release_assets(self, release_id: int) -> List[Dict[str, Any]]:
        url = f"https://api.github.com/repos/{self.repo}/releases/{release_id}/assets"
        headers = {
            "Authorization": f"token {self.token}",
            "Accept": "application/vnd.github.v3+json"
        }
        response = requests.get(url, headers=headers)
        if response.status_code == 200:
            return response.json()
        return []
