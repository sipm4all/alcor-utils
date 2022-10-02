window.addEventListener("DOMContentLoaded", () => {
    const content = document.createTextNode("---");
    document.body.appendChild(content);
    
    const websocket = new WebSocket("ws://localhost:5678/");
    const content = document.createTextNode("---");
    document.body.appendChild(content);
    websocket.onmessage = ({ data }) => {
        content.nodeValue = data;
    };
});
