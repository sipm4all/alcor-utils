#!/usr/bin/env python3

import asyncio
import websockets
import subprocess
import datetime

CONNECTIONS = set()

async def register(websocket):
    CONNECTIONS.add(websocket)
    print('someone connected')
    try:
        await websocket.wait_closed()
    finally:
        CONNECTIONS.remove(websocket)

async def show_stdout():
    while True:
        result = subprocess.run(['./peltier_live_monitor.sh'], stdout=subprocess.PIPE)
        message = result.stdout
        message = datetime.datetime.utcnow().isoformat() + "Z"
        print(message)
        websockets.broadcast(CONNECTIONS, message)
        await asyncio.sleep(1)

async def main():
    async with websockets.serve(register, "localhost", 5678):
        await show_stdout()

if __name__ == "__main__":
    asyncio.run(main())
