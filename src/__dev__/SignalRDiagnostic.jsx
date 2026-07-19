import React, { useEffect, useRef, useState } from "react";
import { HubConnectionBuilder, LogLevel } from "@microsoft/signalr";

const HUB_URL = "https://localhost:7111/hubs/chat";

const styles = {
  panel: { border: "1px solid #e5e7eb", borderRadius: 6, padding: 12, marginBottom: 12 },
  label: { display: "block", marginBottom: 6, fontSize: 13, fontWeight: 600 },
  input: {
    width: "100%",
    padding: "8px 10px",
    fontSize: 14,
    marginBottom: 8,
    boxSizing: "border-box",
  },
  button: { padding: "8px 12px", marginRight: 8, cursor: "pointer" },
  badge: { display: "inline-block", padding: "4px 8px", borderRadius: 999, fontSize: 13 },
  eventRow: {
    padding: "6px 8px",
    borderBottom: "1px solid #f3f4f6",
    fontSize: 13,
    whiteSpace: "pre-wrap",
  },
};

const eventColors = {
  NouveauMessage: "#2563eb", // blue
  MessageLu: "#16a34a", // green
  Notification: "#f97316", // orange
  MessageSupprime: "#6b7280", // gray
  MessageModifie: "#6b7280",
  UserTyping: "#6b7280",
  UserStoppedTyping: "#6b7280",
  default: "#6b7280",
  error: "#dc2626",
};

const now = () => new Date().toISOString();

export default function SignalRDiagnostic() {
  const [conversationId, setConversationId] = useState(0);
  const [token, setToken] = useState(() => localStorage.getItem("token") || "");
  const connectionRef = useRef(null);

  const [status, setStatus] = useState("disconnected"); // disconnected, connecting, connected
  const [connectionId, setConnectionId] = useState(null);

  const [sendContent, setSendContent] = useState("");
  const [sendStatus, setSendStatus] = useState(null);

  const [messageIdToMark, setMessageIdToMark] = useState("");
  const [markStatus, setMarkStatus] = useState(null);

  const [notificationTitre, setNotificationTitre] = useState("");
  const [notificationContenu, setNotificationContenu] = useState("");
  const [notificationStatus, setNotificationStatus] = useState(null);
  const [notificationRecipientId, setNotificationRecipientId] = useState(0);

  const [events, setEvents] = useState([]);
  const eventsRef = useRef([]);
  const monitorRef = useRef(null);

  const [counters, setCounters] = useState({});

  const [logs, setLogs] = useState([]);

  // append event and maintain counters
  const pushEvent = (name, payload) => {
    const color = eventColors[name] || eventColors.default;
    const entry = { ts: now(), name, payload, color };
    eventsRef.current = [...eventsRef.current, entry];
    setEvents(eventsRef.current);
    setCounters((c) => ({ ...c, [name]: (c[name] || 0) + 1 }));
    pushLog(`RECV ${name}`, payload);
  };

  const pushLog = (message, data) => {
    const entry = { ts: now(), message, data };
    setLogs((l) => [...l, entry]);
  };

  useEffect(() => {
    if (!monitorRef.current) return;
    // auto-scroll to bottom when events change
    monitorRef.current.scrollTop = monitorRef.current.scrollHeight;
  }, [events]);

  useEffect(() => {
    // cleanup on unmount
    return () => {
      const conn = connectionRef.current;
      if (conn) {
        try {
          // remove listeners
          conn.off("NouveauMessage");
          conn.off("MessageLu");
          conn.off("MessageSupprime");
          conn.off("MessageModifie");
          conn.off("UserTyping");
          conn.off("UserStoppedTyping");
          conn.off("Notification");
        } catch (e) {}
        try {
          conn.stop();
        } catch (e) {}
      }
    };
  }, []);

  const buildConnection = () => {
    if (connectionRef.current) return connectionRef.current;
    const conn = new HubConnectionBuilder()
      .withUrl(HUB_URL, { accessTokenFactory: () => token || "" })
      .withAutomaticReconnect([0, 2000, 5000, 10000])
      .configureLogging(LogLevel.Information)
      .build();

    // lifecycle handlers
    conn.onreconnecting((err) => {
      setStatus("connecting");
      pushLog("onreconnecting", err ? String(err) : null);
    });

    conn.onreconnected((connId) => {
      setStatus("connected");
      setConnectionId(conn.connectionId || connId || null);
      pushLog("onreconnected", connId || conn.connectionId);
    });

    conn.onclose((err) => {
      setStatus("disconnected");
      setConnectionId(null);
      pushLog("onclose", err ? String(err) : null);
    });

    // event listeners
    conn.on("NouveauMessage", (payload) => pushEvent("NouveauMessage", payload));
    conn.on("MessageLu", (payload) => pushEvent("MessageLu", payload));
    conn.on("MessageSupprime", (payload) => pushEvent("MessageSupprime", payload));
    conn.on("MessageModifie", (payload) => pushEvent("MessageModifie", payload));
    conn.on("UserTyping", (payload) => pushEvent("UserTyping", payload));
    conn.on("UserStoppedTyping", (payload) => pushEvent("UserStoppedTyping", payload));
    conn.on("Notification", (payload) => pushEvent("Notification", payload));

    connectionRef.current = conn;
    return conn;
  };

  const handleConnect = async () => {
    try {
      setStatus("connecting");
      pushLog("connect.start", { conversationId, token: !!token });
      const conn = buildConnection();
      await conn.start();
      setStatus(conn.state === 1 ? "connected" : "connecting");
      setConnectionId(conn.connectionId || null);
      pushLog("connect.started", { connectionId: conn.connectionId });

      // invoke join
      if (conversationId) {
        pushLog("invoke JoinConversation", { conversationId });
        await conn.invoke("JoinConversation", Number(conversationId));
        pushLog("invoke JoinConversation.done", { conversationId });
      }
    } catch (err) {
      setStatus("disconnected");
      pushLog("connect.error", String(err));
    }
  };

  const handleDisconnect = async () => {
    try {
      const conn = connectionRef.current;
      if (!conn) return;
      pushLog("invoke LeaveConversation", { conversationId });
      try {
        await conn.invoke("LeaveConversation", Number(conversationId));
      } catch (e) {
        pushLog("invoke LeaveConversation.error", String(e));
      }
      await conn.stop();
      setStatus("disconnected");
      setConnectionId(null);
      pushLog("disconnect.done", null);
    } catch (err) {
      pushLog("disconnect.error", String(err));
    }
  };

  const handleSendMessage = async () => {
    setSendStatus(null);
    const payload = { idConversation: Number(conversationId), contenu: sendContent };
    pushLog("http POST /api/message", payload);
    try {
      const res = await fetch("https://localhost:7111/api/message", {
        method: "POST",
        headers: { "Content-Type": "application/json", Authorization: `Bearer ${token}` },
        body: JSON.stringify(payload),
      });
      const statusText = `${res.status} ${res.ok ? "✅" : "❌"}`;
      setSendStatus(statusText);
      pushLog("http POST /api/message.response", { status: res.status, ok: res.ok });
    } catch (err) {
      setSendStatus("error");
      pushLog("http POST /api/message.error", String(err));
    }
  };

  const handleSendNotification = async () => {
    setNotificationStatus(null);
    const payload = {
      IdUtilisateur: Number(notificationRecipientId) || Number(conversationId),
      Titre: notificationTitre,
      Contenu: notificationContenu,
      Type: "info",
      LienAction: conversationId ? `/conversations/${conversationId}` : "/",
    };
    pushLog("http POST /api/notifications", payload);
    try {
      const res = await fetch("https://localhost:7111/api/notifications", {
        method: "POST",
        headers: { "Content-Type": "application/json", Authorization: `Bearer ${token}` },
        body: JSON.stringify(payload),
      });
      const statusText = `${res.status} ${res.ok ? "✅" : "❌"}`;
      setNotificationStatus(statusText);
      pushLog("http POST /api/notifications.response", { status: res.status, ok: res.ok });
    } catch (err) {
      setNotificationStatus("error");
      pushLog("http POST /api/notifications.error", String(err));
    }
  };

  const handleMarkAsRead = async () => {
    setMarkStatus(null);
    const id = messageIdToMark;
    pushLog("http PUT /api/message/mark-as-read", { messageId: id });
    try {
      const res = await fetch(`https://localhost:7111/api/message/mark-as-read/${id}`, {
        method: "PUT",
        headers: { Authorization: `Bearer ${token}` },
      });
      const statusText = `${res.status} ${res.ok ? "✅" : "❌"}`;
      setMarkStatus(statusText);
      pushLog("http PUT /api/message/mark-as-read.response", { status: res.status, ok: res.ok });
    } catch (err) {
      setMarkStatus("error");
      pushLog("http PUT /api/message/mark-as-read.error", String(err));
    }
  };

  const simulateUserTyping = async () => {
    const conn = connectionRef.current;
    if (!conn) return pushLog("invoke UserTyping.error", "no connection");
    pushLog("invoke UserTyping", { conversationId, nomUtilisateur: "TestUser" });
    try {
      await conn.invoke("UserTyping", Number(conversationId), "TestUser");
      pushLog("invoke UserTyping.done", null);
    } catch (e) {
      pushLog("invoke UserTyping.error", String(e));
    }
  };

  const simulateUserStoppedTyping = async () => {
    const conn = connectionRef.current;
    if (!conn) return pushLog("invoke UserStoppedTyping.error", "no connection");
    pushLog("invoke UserStoppedTyping", { conversationId });
    try {
      await conn.invoke("UserStoppedTyping", Number(conversationId));
      pushLog("invoke UserStoppedTyping.done", null);
    } catch (e) {
      pushLog("invoke UserStoppedTyping.error", String(e));
    }
  };

  const clearLogs = () => {
    setLogs([]);
    setEvents([]);
    eventsRef.current = [];
    setCounters({});
    pushLog("logs.cleared", null);
  };

  const exportLogs = () => {
    const blob = new Blob([JSON.stringify({ logs, events, counters }, null, 2)], {
      type: "application/json",
    });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `signalr-diagnostic-${new Date().toISOString()}.json`;
    a.click();
    URL.revokeObjectURL(url);
    pushLog("export.logs", null);
  };

  return (
    <div style={{ fontFamily: "Inter, system-ui, Arial, sans-serif", padding: 12 }}>
      <h2>SignalR Diagnostic</h2>

      <div style={styles.panel}>
        <div style={{ marginBottom: 8 }}>
          <label style={styles.label}>Conversation ID</label>
          <input
            style={styles.input}
            type="number"
            value={conversationId}
            onChange={(e) => setConversationId(e.target.value)}
          />
        </div>
        <div style={{ marginBottom: 8 }}>
          <label style={styles.label}>JWT Token</label>
          <input
            style={styles.input}
            value={token}
            onChange={(e) => setToken(e.target.value)}
            placeholder="paste token or use localStorage"
          />
        </div>
        <div>
          <button style={styles.button} onClick={handleConnect}>
            Connect
          </button>
          <button style={styles.button} onClick={handleDisconnect}>
            Disconnect
          </button>
          <span style={{ marginLeft: 12 }}>
            Status:{" "}
            {status === "connected" ? (
              <span style={{ ...styles.badge, background: "#16a34a", color: "white" }}>
                🟢 Connected
              </span>
            ) : status === "connecting" ? (
              <span style={{ ...styles.badge, background: "#f59e0b", color: "white" }}>
                🟡 Connecting
              </span>
            ) : (
              <span style={{ ...styles.badge, background: "#ef4444", color: "white" }}>
                🔴 Disconnected
              </span>
            )}
          </span>
        </div>
        <div style={{ marginTop: 8 }}>
          <strong>ConnectionId:</strong> {connectionId ?? "-"}
        </div>
      </div>

      <div style={styles.panel}>
        <h3>Send Message Test</h3>
        <p style={{ marginTop: 0, marginBottom: 8 }}>
          Do NOT add message to UI — wait for SignalR <strong>NouveauMessage</strong> event.
        </p>
        <textarea
          style={{ ...styles.input, height: 80 }}
          value={sendContent}
          onChange={(e) => setSendContent(e.target.value)}
          placeholder="Message content"
        />
        <div>
          <button style={styles.button} onClick={handleSendMessage}>
            Send
          </button>
          <span style={{ marginLeft: 8 }}>{sendStatus}</span>
        </div>
      </div>

      <div style={styles.panel}>
        <h3>Send Notification Test</h3>
        <p style={{ marginTop: 0, marginBottom: 8 }}>
          Use the API <code>POST /api/notifications</code> to send a notification to a user.
        </p>
        <input
          style={styles.input}
          value={notificationTitre}
          onChange={(e) => setNotificationTitre(e.target.value)}
          placeholder="Notification title"
        />
        <input
          style={styles.input}
          type="number"
          value={notificationRecipientId}
          onChange={(e) => setNotificationRecipientId(Number(e.target.value))}
          placeholder="Recipient user id (idUtilisateur)"
        />
        <textarea
          style={{ ...styles.input, height: 80 }}
          value={notificationContenu}
          onChange={(e) => setNotificationContenu(e.target.value)}
          placeholder="Notification content"
        />
        <div>
          <button style={styles.button} onClick={handleSendNotification}>
            Send Notification
          </button>
          <span style={{ marginLeft: 8 }}>{notificationStatus}</span>
        </div>
      </div>

      <div style={styles.panel}>
        <h3>Mark As Read Test</h3>
        <input
          style={styles.input}
          value={messageIdToMark}
          onChange={(e) => setMessageIdToMark(e.target.value)}
          placeholder="Message ID to mark as read"
        />
        <div>
          <button style={styles.button} onClick={handleMarkAsRead}>
            Mark as read
          </button>
          <span style={{ marginLeft: 8 }}>{markStatus}</span>
        </div>
      </div>

      <div style={styles.panel}>
        <h3>Received Events Monitor</h3>
        <div style={{ marginBottom: 8 }}>
          {Object.keys(counters).length === 0 ? (
            <em>No events yet</em>
          ) : (
            Object.entries(counters).map(([k, v]) => (
              <span
                key={k}
                style={{
                  marginRight: 8,
                  padding: "4px 8px",
                  background: "#f3f4f6",
                  borderRadius: 6,
                }}
              >
                {k}: {v}
              </span>
            ))
          )}
        </div>
        <div
          ref={monitorRef}
          style={{
            maxHeight: 280,
            overflowY: "auto",
            border: "1px solid #f3f4f6",
            borderRadius: 6,
          }}
        >
          {events.map((ev, idx) => (
            <div key={idx} style={{ ...styles.eventRow, borderLeft: `4px solid ${ev.color}` }}>
              <div style={{ fontSize: 12, color: "#6b7280" }}>
                {ev.ts} — <strong style={{ color: ev.color }}>{ev.name}</strong>
              </div>
              <div style={{ marginTop: 6 }}>
                {typeof ev.payload === "object"
                  ? JSON.stringify(ev.payload, null, 2)
                  : String(ev.payload)}
              </div>
            </div>
          ))}
        </div>
      </div>

      <div style={styles.panel}>
        <h3>Typing Indicator Test</h3>
        <div>
          <button style={styles.button} onClick={simulateUserTyping}>
            Simulate UserTyping
          </button>
          <button style={styles.button} onClick={simulateUserStoppedTyping}>
            Simulate UserStoppedTyping
          </button>
        </div>
      </div>

      <div style={styles.panel}>
        <h3>Diagnostics Log</h3>
        <div style={{ marginBottom: 8 }}>
          <button style={styles.button} onClick={clearLogs}>
            Clear logs
          </button>
          <button style={styles.button} onClick={exportLogs}>
            Export logs as JSON
          </button>
        </div>

        <div
          style={{
            maxHeight: 240,
            overflowY: "auto",
            border: "1px solid #f3f4f6",
            borderRadius: 6,
            padding: 8,
          }}
        >
          {logs.map((l, i) => (
            <div key={i} style={{ fontSize: 13, padding: 6, borderBottom: "1px solid #f8fafc" }}>
              <div style={{ color: "#6b7280", fontSize: 12 }}>{l.ts}</div>
              <div style={{ fontWeight: 600 }}>{l.message}</div>
              {l.data && (
                <pre style={{ whiteSpace: "pre-wrap", margin: 0 }}>
                  {typeof l.data === "string" ? l.data : JSON.stringify(l.data, null, 2)}
                </pre>
              )}
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
