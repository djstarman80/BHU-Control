import flet as ft
import requests
import threading
import os
import json
from datetime import datetime

REPO_OWNER = "djstarman80"
REPO_NAME = "BHU-Control"
REPO = f"{REPO_OWNER}/{REPO_NAME}"
CONFIG_FILE = "build_config.json"

PLATFORMS = {
    "web": {"name": "Web", "icon": ft.icons.WEB, "color": ft.colors.BLUE},
    "android": {"name": "Android", "icon": ft.icons.ANDROID, "color": ft.colors.GREEN},
    "ios": {"name": "iOS", "icon": ft.icons.PHONE_IPHONE, "color": ft.colors.ORANGE},
    "linux": {"name": "Linux", "icon": ft.icons.COMPUTER, "color": ft.colors.DEEP_ORANGE},
    "macos": {"name": "macOS", "icon": ft.icons.LAPTOP_MAC, "color": ft.colors.BLUE_GREY},
    "windows": {"name": "Windows", "icon": ft.icons.DESKTOP_WINDOWS, "color": ft.colors.INDIGO},
}

COLORS = {
    "primary": "#2E86C1",
    "secondary": "#3498DB",
    "success": "#27AE60",
    "error": "#E74C3C",
}


class BuildApp:
    def __init__(self, page: ft.Page):
        self.page = page
        self.page.title = "BHU Control - Build Manager"
        self.page.theme_mode = ft.ThemeMode.LIGHT
        self.page.window_width = 600
        self.page.window_height = 700
        self.page.padding = 20
        
        self.selected_platforms = {}
        self.create_release = False
        self.token = ""
        self.build_status = {}
        
        self._load_config()
        self._init_ui()
    
    def _load_config(self):
        if os.path.exists(CONFIG_FILE):
            try:
                with open(CONFIG_FILE, "r") as f:
                    config = json.load(f)
                    self.token = config.get("token", "")
            except:
                self.token = ""
    
    def _save_config(self):
        with open(CONFIG_FILE, "w") as f:
            json.dump({"token": self.token}, f)
    
    def _init_ui(self):
        self.page.clean()
        
        # Header
        header = ft.Container(
            content=ft.Column([
                ft.Text("BHU Control - Build Manager", 
                        size=24, 
                        weight=ft.FontWeight.BOLD,
                        color=COLORS["primary"]),
                ft.Text("Compila desde GitHub Actions",
                        size=12, 
                        color=ft.colors.GREY_700),
            ], spacing=5),
            padding=15,
            bgcolor=ft.colors.WHITE,
            border_radius=10,
        )
        
        # Token input
        self.token_field = ft.TextField(
            label="GitHub Token",
            value=self.token,
            password=True,
            on_change=self._on_token_change,
            width=500,
        )
        
        token_section = ft.Container(
            content=ft.Column([
                ft.Text("Configuración", size=16, weight=ft.FontWeight.BOLD),
                self.token_field,
            ], spacing=10),
            padding=15,
            bgcolor=ft.colors.WHITE,
            border_radius=10,
        )
        
        # Platforms section
        platforms_section = self._build_platforms_section()
        
        # Options
        options_section = self._build_options_section()
        
        # Buttons
        buttons_section = self._build_buttons_section()
        
        # Status
        self.status_text = ft.Text("", size=12)
        self.progress_bar = ft.ProgressBar(width=500, visible=False)
        
        status_container = ft.Container(
            content=ft.Column([
                self.status_text,
                self.progress_bar,
            ], spacing=5),
            padding=10,
            visible=False,
        )
        
        # Artifacts
        self.artifacts_list = ft.Column([], spacing=5)
        artifacts_container = ft.Container(
            content=ft.Column([
                ft.Text("Artifacts", size=16, weight=ft.FontWeight.BOLD),
                self.artifacts_list,
            ], spacing=5),
            padding=15,
            bgcolor=ft.colors.WHITE,
            border_radius=10,
            visible=False,
        )
        self.artifacts_container = artifacts_container
        
        self.page.add(
            header,
            ft.Divider(),
            token_section,
            ft.Divider(),
            platforms_section,
            ft.Divider(),
            options_section,
            ft.Divider(),
            buttons_section,
            ft.Divider(),
            status_container,
            artifacts_container,
        )
    
    def _on_token_change(self, e):
        self.token = e.control.value
        self._save_config()
    
    def _build_platforms_section(self):
        title = ft.Text("Seleccionar Plataformas", size=16, weight=ft.FontWeight.BOLD)
        
        def create_platform_card(platform_id, platform_info):
            def toggle(e):
                if platform_id in self.selected_platforms:
                    del self.selected_platforms[platform_id]
                else:
                    self.selected_platforms[platform_id] = True
                self._update_platform_cards()
            
            card = ft.Container(
                content=ft.Column([
                    ft.Icon(platform_info["icon"], size=30, color=platform_info["color"]),
                    ft.Text(platform_info["name"], size=11, weight=ft.FontWeight.BOLD),
                ], horizontal_alignment=ft.CrossAxisAlignment.CENTER, spacing=2),
                width=80,
                height=70,
                border_radius=8,
                bgcolor=ft.colors.WHITE,
                border=ft.border.all(2, ft.colors.GREY_300),
                on_click=toggle,
                ink=True,
                alignment=ft.alignment.center,
            )
            card.platform_id = platform_id
            return card
        
        row1 = ft.Row([
            create_platform_card("web", PLATFORMS["web"]),
            create_platform_card("android", PLATFORMS["android"]),
            create_platform_card("ios", PLATFORMS["ios"]),
        ], spacing=10, alignment=ft.MainAxisAlignment.CENTER)
        
        row2 = ft.Row([
            create_platform_card("linux", PLATFORMS["linux"]),
            create_platform_card("macos", PLATFORMS["macos"]),
            create_platform_card("windows", PLATFORMS["windows"]),
        ], spacing=10, alignment=ft.MainAxisAlignment.CENTER)
        
        self.platform_cards = [row1, row2]
        
        return ft.Container(
            content=ft.Column([title, row1, row2], spacing=10),
            padding=15,
            bgcolor=ft.colors.WHITE,
            border_radius=10,
        )
    
    def _update_platform_cards(self):
        for row in self.platform_cards:
            for card in row.controls:
                if hasattr(card, "platform_id"):
                    if card.platform_id in self.selected_platforms:
                        card.bgcolor = ft.colors.BLUE_50
                        card.border = ft.border.all(2, COLORS["primary"])
                    else:
                        card.bgcolor = ft.colors.WHITE
                        card.border = ft.border.all(2, ft.colors.GREY_300)
        self.page.update()
    
    def _build_options_section(self):
        self.chk_release = ft.Checkbox(
            label="Crear Release automáticamente",
            value=False,
            on_change=lambda e: setattr(self, 'create_release', e.control.value)
        )
        
        return ft.Container(
            content=ft.Column([self.chk_release], spacing=5),
            padding=15,
            bgcolor=ft.colors.WHITE,
            border_radius=10,
        )
    
    def _build_buttons_section(self):
        self.btn_compilar = ft.ElevatedButton(
            content=ft.Row([
                ft.Icon(ft.icons.PLAY_ARROW, color=ft.colors.WHITE),
                ft.Text("COMPILAR", weight=ft.FontWeight.BOLD),
            ], spacing=5),
            bgcolor=COLORS["primary"],
            width=150,
            height=40,
            on_click=self._start_build,
        )
        
        self.btn_descargar = ft.ElevatedButton(
            content=ft.Row([
                ft.Icon(ft.icons.DOWNLOAD, color=ft.colors.WHITE),
                ft.Text("DESCARGAR", weight=ft.FontWeight.BOLD),
            ], spacing=5),
            bgcolor=COLORS["secondary"],
            width=150,
            height=40,
            disabled=True,
            on_click=self._download_artifacts,
        )
        
        return ft.Container(
            content=ft.Row([self.btn_compilar, self.btn_descargar], spacing=20, alignment=ft.MainAxisAlignment.CENTER),
            padding=15,
        )
    
    def _start_build(self, e):
        if not self.token:
            self._show_message("Ingresa tu GitHub Token", ft.colors.ORANGE)
            return
        
        if not self.selected_platforms:
            self._show_message("Selecciona al menos una plataforma", ft.colors.ORANGE)
            return
        
        self._show_message("Iniciando compilación...", ft.colors.BLUE)
        self.progress_bar.visible = True
        self.btn_compilar.disabled = True
        self.page.update()
        
        # Run in background
        threading.Thread(target=self._run_build, daemon=True).start()
    
    def _run_build(self):
        try:
            platforms_str = ",".join(self.selected_platforms.keys())
            
            # Trigger workflow dispatch via API
            url = f"https://api.github.com/repos/{REPO}/actions/workflows/deploy.yml/dispatch"
            headers = {
                "Authorization": f"token {self.token}",
                "Accept": "application/vnd.github.v3+json",
                "Content-Type": "application/json"
            }
            data = {
                "ref": "main",
                "inputs": {
                    "platforms": platforms_str,
                    "create_release": str(self.create_release).lower()
                }
            }
            
            response = requests.post(url, headers=headers, json=data)
            
            if response.status_code == 204:
                self._show_message("✓ Build iniciado en GitHub Actions!", ft.colors.GREEN)
                self.btn_descargar.disabled = False
            else:
                self._show_message(f"Error: {response.status_code} - {response.text}", ft.colors.RED)
                
        except Exception as ex:
            self._show_message(f"Error: {str(ex)}", ft.colors.RED)
        
        finally:
            self.progress_bar.visible = False
            self.btn_compilar.disabled = False
            self.page.update()
    
    def _download_artifacts(self, e):
        if not self.token:
            self._show_message("Ingresa tu GitHub Token", ft.colors.ORANGE)
            return
        
        self._show_message("Buscando artifacts...", ft.colors.BLUE)
        self.artifacts_container.visible = True
        self.artifacts_list.controls.clear()
        self.page.update()
        
        threading.Thread(target=self._run_download, daemon=True).start()
    
    def _run_download(self):
        try:
            # Get latest workflow run
            url = f"https://api.github.com/repos/{REPO}/actions/runs"
            headers = {
                "Authorization": f"token {self.token}",
                "Accept": "application/vnd.github.v3+json"
            }
            
            response = requests.get(url, headers=headers)
            if response.status_code == 200:
                runs = response.json().get("workflow_runs", [])
                if runs:
                    run_id = runs[0]["id"]
                    
                    # Get artifacts
                    artifacts_url = f"https://api.github.com/repos/{REPO}/actions/runs/{run_id}/artifacts"
                    artifacts_response = requests.get(artifacts_url, headers=headers)
                    
                    if artifacts_response.status_code == 200:
                        artifacts = artifacts_response.json().get("artifacts", [])
                        
                        if artifacts:
                            for artifact in artifacts:
                                size_mb = artifact["size"] / (1024 * 1024)
                                
                                def download(url):
                                    import webbrowser
                                    webbrowser.open(url)
                                
                                self.artifacts_list.controls.append(
                                    ft.ListTile(
                                        leading=ft.Icon(ft.icons.FOLDER_ZIP),
                                        title=ft.Text(artifact["name"]),
                                        subtitle=ft.Text(f"{size_mb:.2f} MB"),
                                        trailing=ft.ElevatedButton(
                                            "Descargar",
                                            on_click=lambda _, url=artifact["archive_download_url"]: download(url),
                                        ),
                                    )
                                )
                            
                            self._show_message(f"✓ {len(artifacts)} artifacts encontrados", ft.colors.GREEN)
                        else:
                            self._show_message("No hay artifacts disponibles", ft.colors.ORANGE)
                            self.artifacts_list.controls.append(
                                ft.Text("No hay artifacts disponibles", color=ft.colors.GREY)
                            )
                else:
                    self._show_message("No hay runs de workflow", ft.colors.ORANGE)
            else:
                self._show_message(f"Error: {response.status_code}", ft.colors.RED)
                
        except Exception as ex:
            self._show_message(f"Error: {str(ex)}", ft.colors.RED)
        
        self.page.update()
    
    def _show_message(self, message: str, color):
        self.status_text.value = message
        self.status_text.color = color
        self.page.update()


def main(page: ft.Page):
    BuildApp(page)


if __name__ == "__main__":
    ft.app(target=main)
