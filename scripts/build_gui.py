import flet as ft
import os
import requests
import time

GITHUB_TOKEN = os.environ.get("GITHUB_TOKEN", "")
REPO_OWNER = "djstarman80"
REPO_NAME = "BHU-Control"
REPO = f"{REPO_OWNER}/{REPO_NAME}"

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
    "warning": "#F39C12",
    "error": "#E74C3C",
    "background": "#F5F5F5",
}


class BuildManagerApp:
    def __init__(self, page: ft.Page):
        self.page = page
        self.page.title = "BHU Control - Build Manager"
        self.page.theme_mode = ft.ThemeMode.LIGHT
        self.page.padding = 20
        self.selected_platforms = {}
        self.create_release = False
        self.generate_release_notes = False
        
        self._init_ui()
    
    def _init_ui(self):
        self.page.clean()
        
        header = ft.Container(
            content=ft.Column([
                ft.Text("BHU Control - Build Manager", 
                        size=28, 
                        weight=ft.FontWeight.BOLD,
                        color=COLORS["primary"]),
                ft.Text("Selecciona las plataformas y compila desde GitHub Actions",
                        size=14, 
                        color=ft.colors.GREY_700),
            ], spacing=5),
            padding=20,
            bgcolor=ft.colors.WHITE,
            border_radius=10,
            shadow=ft.BoxShadow(blur_radius=10, color=ft.colors.GREY_300),
        )
        
        platforms_section = self._build_platforms_section()
        options_section = self._build_options_section()
        buttons_section = self._build_buttons_section()
        
        self.status_container = ft.Container(
            content=ft.Column([], spacing=10),
            padding=20,
            bgcolor=ft.colors.WHITE,
            border_radius=10,
            visible=False,
        )
        
        self.artifacts_container = ft.Container(
            content=ft.Column([], spacing=10),
            padding=20,
            bgcolor=ft.colors.WHITE,
            border_radius=10,
            visible=False,
        )
        
        main_content = ft.Column([
            header,
            ft.Divider(height=20),
            platforms_section,
            ft.Divider(height=20),
            options_section,
            ft.Divider(height=20),
            buttons_section,
            ft.Divider(height=20),
            self.status_container,
            self.artifacts_container,
        ], scroll=ft.ScrollMode.AUTO)
        
        self.page.add(main_content)
    
    def _build_platforms_section(self):
        title = ft.Text("Seleccionar Plataformas", 
                       size=18, 
                       weight=ft.FontWeight.BOLD,
                       color=ft.colors.GREY_800)
        
        def create_platform_card(platform_id, platform_info):
            card_ref = {"card": None}
            
            def toggle_platform(e):
                if platform_id in self.selected_platforms:
                    del self.selected_platforms[platform_id]
                else:
                    self.selected_platforms[platform_id] = True
                
                card = card_ref["card"]
                card.bgcolor = ft.colors.WHITE if platform_id not in self.selected_platforms else ft.colors.BLUE_50
                card.border = ft.border.all(2, ft.colors.GREY_300) if platform_id not in self.selected_platforms else ft.border.all(2, COLORS["primary"])
                self.page.update()
            
            card = ft.Container(
                content=ft.Column([
                    ft.Icon(platform_info["icon"], size=40, color=platform_info["color"]),
                    ft.Text(platform_info["name"], size=14, weight=ft.FontWeight.BOLD),
                ], horizontal_alignment=ft.CrossAxisAlignment.CENTER, spacing=10),
                width=100,
                height=100,
                border_radius=10,
                bgcolor=ft.colors.WHITE,
                border=ft.border.all(2, ft.colors.GREY_300),
                on_click=toggle_platform,
                ink=True,
                alignment=ft.alignment.center,
            )
            card_ref["card"] = card
            return card
        
        row1 = ft.Row([
            create_platform_card("web", PLATFORMS["web"]),
            create_platform_card("android", PLATFORMS["android"]),
            create_platform_card("ios", PLATFORMS["ios"]),
        ], spacing=15, alignment=ft.MainAxisAlignment.CENTER)
        
        row2 = ft.Row([
            create_platform_card("linux", PLATFORMS["linux"]),
            create_platform_card("macos", PLATFORMS["macos"]),
            create_platform_card("windows", PLATFORMS["windows"]),
        ], spacing=15, alignment=ft.MainAxisAlignment.CENTER)
        
        return ft.Container(
            content=ft.Column([title, row1, row2], spacing=15),
            padding=20,
            bgcolor=ft.colors.WHITE,
            border_radius=10,
            shadow=ft.BoxShadow(blur_radius=5, color=ft.colors.GREY_300),
        )
    
    def _build_options_section(self):
        title = ft.Text("Opciones Adicionales", 
                       size=18, 
                       weight=ft.FontWeight.BOLD,
                       color=ft.colors.GREY_800)
        
        def toggle_create_release(e):
            self.create_release = e.control.value
            self.page.update()
        
        def toggle_release_notes(e):
            self.generate_release_notes = e.control.value
            self.page.update()
        
        checkbox_release = ft.Checkbox(
            label="Crear Release automáticamente",
            value=False,
            on_change=toggle_create_release,
        )
        
        checkbox_notes = ft.Checkbox(
            label="Generar notas de Release",
            value=False,
            on_change=toggle_release_notes,
        )
        
        return ft.Container(
            content=ft.Column([title, checkbox_release, checkbox_notes], spacing=10),
            padding=20,
            bgcolor=ft.colors.WHITE,
            border_radius=10,
            shadow=ft.BoxShadow(blur_radius=5, color=ft.colors.GREY_300),
        )
    
    def _build_buttons_section(self):
        self.btn_compilar = ft.ElevatedButton(
            content=ft.Row([
                ft.Icon(ft.icons.PLAY_ARROW, color=ft.colors.WHITE),
                ft.Text("COMPILAR", weight=ft.FontWeight.BOLD, color=ft.colors.WHITE),
            ], spacing=10),
            bgcolor=COLORS["primary"],
            width=200,
            height=50,
            on_click=self.start_build,
        )
        
        self.btn_descargar = ft.ElevatedButton(
            content=ft.Row([
                ft.Icon(ft.icons.DOWNLOAD, color=ft.colors.WHITE),
                ft.Text("DESCARGAR", weight=ft.FontWeight.BOLD, color=ft.colors.WHITE),
            ], spacing=10),
            bgcolor=COLORS["secondary"],
            width=200,
            height=50,
            disabled=True,
            on_click=self.download_artifacts,
        )
        
        self.btn_release = ft.ElevatedButton(
            content=ft.Row([
                ft.Icon(ft.icons.NEW_RELEASES, color=ft.colors.WHITE),
                ft.Text("CREAR RELEASE", weight=ft.FontWeight.BOLD, color=ft.colors.WHITE),
            ], spacing=10),
            bgcolor=COLORS["success"],
            width=200,
            height=50,
            disabled=True,
            on_click=self.create_release_handler,
        )
        
        return ft.Container(
            content=ft.Row([
                self.btn_compilar,
                self.btn_descargar,
                self.btn_release,
            ], spacing=20, alignment=ft.MainAxisAlignment.CENTER),
            padding=20,
        )
    
    def start_build(self, e):
        if not self.selected_platforms:
            self._show_snackbar("Selecciona al menos una plataforma", ft.colors.ORANGE)
            return
        
        self.status_container.visible = True
        self.status_container.content = ft.Column([
            ft.Text("Compilando en GitHub Actions...", size=18, weight=ft.FontWeight.BOLD),
            ft.Text("Esta acción se ejecuta desde GitHub. Abre la pestaña de Actions para ver el progreso.",
                    size=12, color=ft.colors.GREY_600),
            ft.ElevatedButton(
                "Abrir GitHub Actions",
                icon=ft.icons.OPEN_IN_NEW,
                on_click=lambda _: self.page.launch_url(f"https://github.com/{REPO}/actions"),
            ),
        ], spacing=10)
        self.page.update()
        
        platforms_str = ",".join(self.selected_platforms.keys())
        
        github_token = GITHUB_TOKEN or os.environ.get("GH_TOKEN", "")
        
        if github_token:
            self._trigger_workflow_with_token(platforms_str)
        else:
            self._show_snackbar("Token de GitHub no encontrado. Abre Actions manualmente.", ft.colors.ORANGE)
            self.page.launch_url(f"https://github.com/{REPO}/actions")
    
    def _trigger_workflow_with_token(self, platforms: str):
        url = f"https://api.github.com/repos/{REPO}/dispatches"
        headers = {
            "Authorization": f"token {GITHUB_TOKEN}",
            "Accept": "application/vnd.github.v3+json"
        }
        data = {
            "event_type": "build-selection",
            "client_payload": {
                "platforms": platforms,
                "create_release": self.create_release,
                "generate_notes": self.generate_release_notes
            }
        }
        
        try:
            response = requests.post(url, headers=headers, json=data)
            if response.status_code == 204:
                self._show_snackbar("Build iniciado en GitHub Actions!", ft.colors.GREEN)
                time.sleep(3)
                self.btn_descargar.disabled = False
                self.btn_release.disabled = not self.create_release
                self.page.update()
            else:
                self._show_snackbar(f"Error: {response.status_code}", ft.colors.RED)
        except Exception as ex:
            self._show_snackbar(f"Error: {str(ex)}", ft.colors.RED)
    
    def download_artifacts(self, e):
        if not GITHUB_TOKEN:
            self._show_snackbar("Token de GitHub requerido para descargar", ft.colors.ORANGE)
            return
        
        self._show_snackbar("Descargando artifacts...", ft.colors.BLUE)
        
        try:
            run_url = f"https://api.github.com/repos/{REPO}/actions/runs"
            headers = {
                "Authorization": f"token {GITHUB_TOKEN}",
                "Accept": "application/vnd.github.v3+json"
            }
            
            response = requests.get(run_url, headers=headers)
            if response.status_code == 200:
                runs = response.json().get("workflow_runs", [])
                if runs:
                    run_id = runs[0]["id"]
                    artifacts_url = f"https://api.github.com/repos/{REPO}/actions/runs/{run_id}/artifacts"
                    artifacts_response = requests.get(artifacts_url, headers=headers)
                    
                    if artifacts_response.status_code == 200:
                        artifacts = artifacts_response.json().get("artifacts", [])
                        
                        if artifacts:
                            self.artifacts_container.visible = True
                            self.artifacts_container.content = ft.Column([
                                ft.Text("Artifacts Disponibles", size=18, weight=ft.FontWeight.BOLD),
                            ], spacing=10)
                            
                            for artifact in artifacts:
                                size_mb = artifact["size"] / (1024 * 1024)
                                
                                self.artifacts_container.content.controls.append(
                                    ft.ListTile(
                                        leading=ft.Icon(ft.icons.FOLDER_ZIP),
                                        title=ft.Text(artifact["name"]),
                                        subtitle=ft.Text(f"{size_mb:.2f} MB"),
                                        trailing=ft.ElevatedButton(
                                            "Abrir",
                                            on_click=lambda _, url=artifact["browser_download_url"]: self.page.launch_url(url),
                                        ),
                                    )
                                )
                            
                            self._show_snackbar(f"{len(artifacts)} artifacts encontrados", ft.colors.GREEN)
                            self.page.update()
                        else:
                            self._show_snackbar("No hay artifacts disponibles", ft.colors.ORANGE)
        except Exception as ex:
            self._show_snackbar(f"Error: {str(ex)}", ft.colors.RED)
    
    def create_release_handler(self, e):
        if not GITHUB_TOKEN:
            self._show_snackbar("Token de GitHub requerido", ft.colors.ORANGE)
            return
        
        self._show_snackbar("Creando release...", ft.colors.BLUE)
        
        try:
            releases_url = f"https://api.github.com/repos/{REPO}/releases"
            headers = {
                "Authorization": f"token {GITHUB_TOKEN}",
                "Accept": "application/vnd.github.v3+json"
            }
            
            from datetime import datetime
            platforms_list = ", ".join(self.selected_platforms.keys())
            body = f"""Release automático generado desde Flet GUI

Plataformas compiladas:
- {platforms_list}

Fecha: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}"""
            
            data = {
                "tag_name": f"v{datetime.now().strftime('%Y%m%d')}",
                "name": f"BHU Control {datetime.now().strftime('%Y.%m.%d')}",
                "body": body,
                "draft": False,
                "prerelease": False
            }
            
            response = requests.post(releases_url, headers=headers, json=data)
            
            if response.status_code in [200, 201]:
                self._show_snackbar("Release creado exitosamente!", ft.colors.GREEN)
                self.page.launch_url(f"https://github.com/{REPO}/releases")
            else:
                self._show_snackbar(f"Error: {response.status_code}", ft.colors.RED)
                
        except Exception as ex:
            self._show_snackbar(f"Error: {str(ex)}", ft.colors.RED)
    
    def _show_snackbar(self, message: str, color: str = ft.colors.BLUE):
        self.page.show_snack_bar(
            ft.SnackBar(
                content=ft.Text(message),
                bgcolor=color,
                duration=3,
            )
        )


def main(page: ft.Page):
    BuildManagerApp(page)


if __name__ == "__main__":
    ft.app(target=main, view=ft.WEB_BROWSER)
