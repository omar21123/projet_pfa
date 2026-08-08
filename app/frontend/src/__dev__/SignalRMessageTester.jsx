import { useEffect, useRef, useState } from "react";
import { HubConnectionBuilder, HubConnectionState } from "@microsoft/signalr";

const API_BASE_URL = "http://localhost:5052";

const statusEmoji = {
  disconnected: "🔴 Disconnected",
  connecting: "🟡 Connecting",
  connected: "🟢 Connected",
};

const SignalRMessageTester = () => {
  const connectionRef = useRef(null);
  const [conversationId, setConversationId] = useState("");
  const [messageText, setMessageText] = useState("");
  const [connectionStatus, setConnectionStatus] = useState("disconnected");
  const [responseStatus, setResponseStatus] = useState(null);
  const [receivedMessages, setReceivedMessages] = useState([]);
  const [logs, setLogs] = useState([]);

  const addLog = (text) => {
    setLogs((currentLogs) => [
      { timestamp: new Date().toLocaleTimeString(), text },
      ...currentLogs,
    ]);
  };

  const logLifecycle = (eventName, error) => {
    addLog(error ? `${eventName} - ${error?.message || "unknown error"}` : `${eventName}`);
  };

  const createConnection = () => {
    const token = localStorage.getItem("token");
    return new HubConnectionBuilder()
      .withUrl(`${API_BASE_URL}/hubs/chat`, {
        accessTokenFactory: () => token || "",
      })
      .withAutomaticReconnect()
      .build();
  };

  const connect = async () => {
    if (connectionStatus === "connecting" || connectionStatus === "connected") {
      return;
    }

    setConnectionStatus("connecting");
    addLog("Connecting...");

    const connection = createConnection();
    connectionRef.current = connection;

    connection.onreconnecting((error) => {
      setConnectionStatus("connecting");
      logLifecycle("onreconnecting", error);
    });

    connection.onreconnected((connectionId) => {
      setConnectionStatus("connected");
      logLifecycle("onreconnected");
      addLog(`Reconnected with connectionId: ${connectionId}`);
    });

    connection.onclose((error) => {
      setConnectionStatus("disconnected");
      logLifecycle("onclose", error);
    });

    connection.on("NouveauMessage", (message) => {
      addLog(`Received NouveauMessage event: ${JSON.stringify(message)}`);
      setReceivedMessages((current) => [
        { ...message, receivedAt: new Date().toLocaleTimeString() },
        ...current,
      ]);
    });

    try {
      await connection.start();
      setConnectionStatus("connected");
      addLog("Connected successfully");

      if (conversationId) {
        try {
          await connection.invoke("JoinConversation", conversationId);
          addLog(`Joined conversation ${conversationId}`);
        } catch (invokeError) {
          addLog(`JoinConversation failed: ${invokeError?.message || invokeError}`);
        }
      }
    } catch (error) {
      setConnectionStatus("disconnected");
      addLog(`Connection failed: ${error?.message || error}`);
    }
  };

  const disconnect = async () => {
    const connection = connectionRef.current;
    if (!connection) {
      return;
    }

    try {
      await connection.stop();
      addLog("Disconnected successfully");
    } catch (error) {
      addLog(`Disconnect failed: ${error?.message || error}`);
    }

    connectionRef.current = null;
    setConnectionStatus("disconnected");
  };

  const handleSendMessage = async () => {
    if (!conversationId || !messageText) {
      addLog("Send skipped: conversationId or messageText missing");
      return;
    }

    const token = localStorage.getItem("token");
    const body = { idConversation: Number(conversationId), contenu: messageText };

    try {
      const response = await fetch(`${API_BASE_URL}/api/message`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: token ? `Bearer ${token}` : "",
        },
        body: JSON.stringify(body),
      });

      setResponseStatus(response.status);
      addLog(`Sent POST /api/message -> status ${response.status}`);

      if (response.status === 202) {
        setMessageText("");
      }
    } catch (error) {
      setResponseStatus(null);
      addLog(`Send request failed: ${error?.message || error}`);
    }
  };

  useEffect(() => {
    return () => {
      const connection = connectionRef.current;
      if (connection) {
        connection.stop().catch(() => {
          /* ignore cleanup errors */
        });
      }
    };
  }, []);

  useEffect(() => {
    if (connectionStatus === "connected" && connectionRef.current && conversationId) {
      connectionRef.current
        .invoke("JoinConversation", conversationId)
        .then(() => addLog(`Joined conversation ${conversationId}`))
        .catch((error) => addLog(`JoinConversation failed: ${error?.message || error}`));
    }
  }, [conversationId, connectionStatus]);

  const connectionLabel = statusEmoji[connectionStatus] || statusEmoji.disconnected;

  return (
    <div
      style={{ padding: 20, fontFamily: "Segoe UI, sans-serif", maxWidth: 760, margin: "0 auto" }}
    >
      <h2 style={{ marginBottom: 12 }}>SignalR Message Tester</h2>

      <section
        style={{ marginBottom: 20, padding: 16, border: "1px solid #ddd", borderRadius: 12 }}
      >
        <h3 style={{ marginBottom: 8 }}>Connection panel</h3>
        <div style={{ display: "flex", gap: 12, flexWrap: "wrap", alignItems: "center" }}>
          <label style={{ display: "flex", flexDirection: "column", flex: "1 1 240px" }}>
            Conversation ID
            <input
              type="text"
              value={conversationId}
              onChange={(event) => setConversationId(event.target.value)}
              style={{ marginTop: 6, padding: 8, borderRadius: 8, border: "1px solid #ccc" }}
            />
          </label>
          <button
            type="button"
            onClick={connectionStatus === "connected" ? disconnect : connect}
            style={{
              padding: "10px 16px",
              borderRadius: 8,
              border: "none",
              cursor: "pointer",
              backgroundColor: connectionStatus === "connected" ? "#d33" : "#2a7",
              color: "#fff",
              minWidth: 120,
            }}
          >
            {connectionStatus === "connected" ? "Disconnect" : "Connect"}
          </button>
          <div style={{ fontWeight: 600 }}>{connectionLabel}</div>
        </div>
      </section>

      {connectionStatus === "connected" && (
        <section
          style={{ marginBottom: 20, padding: 16, border: "1px solid #ddd", borderRadius: 12 }}
        >
          <h3 style={{ marginBottom: 8 }}>Send message panel</h3>
          <div style={{ display: "flex", gap: 12, flexWrap: "wrap", alignItems: "center" }}>
            <input
              type="text"
              placeholder="Message content"
              value={messageText}
              onChange={(event) => setMessageText(event.target.value)}
              style={{ flex: "1 1 320px", padding: 8, borderRadius: 8, border: "1px solid #ccc" }}
            />
            <button
              type="button"
              onClick={handleSendMessage}
              style={{
                padding: "10px 16px",
                borderRadius: 8,
                border: "none",
                cursor: "pointer",
                backgroundColor: "#1266f1",
                color: "#fff",
                minWidth: 120,
              }}
            >
              Send
            </button>
          </div>
          <p style={{ marginTop: 12 }}>
            HTTP response status: <strong>{responseStatus ?? "N/A"}</strong>
          </p>
        </section>
      )}

      <section
        style={{ marginBottom: 20, padding: 16, border: "1px solid #ddd", borderRadius: 12 }}
      >
        <h3 style={{ marginBottom: 8 }}>Received messages panel</h3>
        <p style={{ marginBottom: 12 }}>Total messages received: {receivedMessages.length}</p>
        <div style={{ display: "grid", gap: 10 }}>
          {receivedMessages.map((message, index) => (
            <div
              key={`${message.idMessage ?? index}-${message.receivedAt}`}
              style={{
                padding: 12,
                borderRadius: 10,
                border: "1px solid #ccc",
                backgroundColor: index === 0 ? "#eff9ff" : "#fff",
              }}
            >
              <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 8 }}>
                <strong>{message.nomExpediteur ?? "Unknown"}</strong>
                <span style={{ fontSize: 12, color: "#555" }}>{message.receivedAt}</span>
              </div>
              <div style={{ fontSize: 14, color: "#111" }}>
                {message.contenu ?? JSON.stringify(message)}
              </div>
            </div>
          ))}
          {receivedMessages.length === 0 && (
            <div style={{ color: "#555" }}>No SignalR messages received yet.</div>
          )}
        </div>
      </section>

      <section
        style={{ marginBottom: 20, padding: 16, border: "1px solid #ddd", borderRadius: 12 }}
      >
        <h3 style={{ marginBottom: 8 }}>Diagnostics panel</h3>
        <button
          type="button"
          onClick={() => setLogs([])}
          style={{
            marginBottom: 12,
            padding: "8px 12px",
            borderRadius: 8,
            border: "1px solid #999",
            backgroundColor: "#fff",
            cursor: "pointer",
          }}
        >
          Clear logs
        </button>
        <div
          style={{
            maxHeight: 320,
            overflowY: "auto",
            padding: 10,
            backgroundColor: "#09090908",
            borderRadius: 10,
            border: "1px solid #eee",
          }}
        >
          {logs.length === 0 && <div style={{ color: "#555" }}>No logs yet.</div>}
          {logs.map((entry, index) => (
            <div key={`${entry.timestamp}-${index}`} style={{ marginBottom: 10 }}>
              <div style={{ fontSize: 12, color: "#666" }}>{entry.timestamp}</div>
              <div style={{ whiteSpace: "pre-wrap", fontSize: 14 }}>{entry.text}</div>
            </div>
          ))}
        </div>
      </section>
    </div>
  );
};

export default SignalRMessageTester;
