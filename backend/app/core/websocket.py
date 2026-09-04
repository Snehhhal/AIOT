import json
from typing import List
from fastapi import WebSocket


class ConnectionManager:
    def __init__(self):
        self.telemetry_connections: List[WebSocket] = []
        self.alert_connections: List[WebSocket] = []

    async def connect_telemetry(self, websocket: WebSocket):
        await websocket.accept()
        self.telemetry_connections.append(websocket)

    def disconnect_telemetry(self, websocket: WebSocket):
        if websocket in self.telemetry_connections:
            self.telemetry_connections.remove(websocket)

    async def broadcast_telemetry(self, message: dict):
        for connection in list(self.telemetry_connections):
            try:
                await connection.send_json(message)
            except Exception:
                self.disconnect_telemetry(connection)

    async def connect_alerts(self, websocket: WebSocket):
        await websocket.accept()
        self.alert_connections.append(websocket)

    def disconnect_alerts(self, websocket: WebSocket):
        if websocket in self.alert_connections:
            self.alert_connections.remove(websocket)

    async def broadcast_alert(self, message: dict):
        for connection in list(self.alert_connections):
            try:
                await connection.send_json(message)
            except Exception:
                self.disconnect_alerts(connection)


ws_manager = ConnectionManager()
