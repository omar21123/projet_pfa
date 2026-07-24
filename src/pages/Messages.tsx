import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import {
  Send,
  ArrowLeft,
  Phone,
  MoreVertical,
  Search,
  Image as ImageIcon,
  Paperclip,
  Smile,
  Check,
  CheckCheck,
  Tag,
} from "lucide-react";
import Navbar from "@/components/Navbar";
import Footer from "@/components/Footer";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { ScrollArea } from "@/components/ui/scroll-area";
import { Badge } from "@/components/ui/badge";
import { cn } from "@/lib/utils";
import { useLanguage } from "@/contexts/LanguageContext";
import { conversationApi, messageApi } from "@/api";
import { useUser } from "@/hooks/useUser";
import type { ConversationDto } from "@/types/conversation.types";
import type { CreateMessageRequest, MessageDto } from "@/types/message.types";

const convItemVariants = {
  hidden: { opacity: 0, x: -20 },
  visible: (i: number) => ({
    opacity: 1,
    x: 0,
    transition: { delay: i * 0.04, duration: 0.3, ease: [0.22, 1, 0.36, 1] as const },
  }),
};

const messageVariants = {
  hidden: (sender: boolean) => ({ opacity: 0, x: sender ? 20 : -20, scale: 0.96 }),
  visible: () => ({
    opacity: 1,
    x: 0,
    scale: 1,
    transition: { duration: 0.25, ease: [0.22, 1, 0.36, 1] as const },
  }),
};

/** Sanitize text content to prevent XSS — strip tags, keep plain text. */
const sanitizeText = (input: string): string =>
  input
    .replace(/<[^>]*>/g, "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;");

/** Relative date: À l'instant / il y a Xm / Aujourd'hui à HH:mm / Hier à HH:mm / date courte. */
const formatRelative = (dateString: string): string => {
  const date = new Date(dateString);
  const now = new Date();
  const diffMs = now.getTime() - date.getTime();
  const diffMin = Math.floor(diffMs / 60000);

  if (diffMin < 1) return "À l'instant";
  if (diffMin < 60) return `Il y a ${diffMin} min`;

  const sameDay =
    date.getDate() === now.getDate() &&
    date.getMonth() === now.getMonth() &&
    date.getFullYear() === now.getFullYear();
  const yesterday = new Date(now);
  yesterday.setDate(now.getDate() - 1);
  const isYesterday =
    date.getDate() === yesterday.getDate() &&
    date.getMonth() === yesterday.getMonth() &&
    date.getFullYear() === yesterday.getFullYear();

  const hhmm = date.toLocaleTimeString("fr-FR", { hour: "2-digit", minute: "2-digit" });
  if (sameDay) return `Aujourd'hui à ${hhmm}`;
  if (isYesterday) return `Hier à ${hhmm}`;

  const diffDays = Math.floor(diffMs / 86400000);
  if (diffDays < 7) return date.toLocaleDateString("fr-FR", { weekday: "long" });
  return date.toLocaleDateString("fr-FR");
};

const formatHour = (dateString: string): string =>
  new Date(dateString).toLocaleTimeString("fr-FR", { hour: "2-digit", minute: "2-digit" });

/** Status ticks: sent (one check), delivered (double gray), read (double primary). */
type MessageStatus = "sent" | "delivered" | "read";

const StatusTicks = ({ status }: { status: MessageStatus }) => {
  if (status === "sent") {
    return <Check className="h-3.5 w-3.5 opacity-70" />;
  }
  if (status === "delivered") {
    return <CheckCheck className="h-3.5 w-3.5 opacity-70" />;
  }
  return <CheckCheck className="h-3.5 w-3.5 text-sky-300" />;
};

const TypingDots = () => (
  <div className="flex items-center gap-1">
    {[0, 1, 2].map((i) => (
      <motion.span
        key={i}
        className="block h-1.5 w-1.5 rounded-full bg-muted-foreground/70"
        animate={{ y: [0, -3, 0], opacity: [0.4, 1, 0.4] }}
        transition={{ duration: 0.9, repeat: Infinity, delay: i * 0.15 }}
      />
    ))}
  </div>
);

const Messages = () => {
  const [conversations, setConversations] = useState<ConversationDto[]>([]);
  const [selectedConvId, setSelectedConvId] = useState<number | null>(null);
  const [messages, setMessages] = useState<MessageDto[]>([]);
  const [newMessage, setNewMessage] = useState("");
  const [searchQuery, setSearchQuery] = useState("");
  const [loadingConversations, setLoadingConversations] = useState(false);
  const [loadingMessages, setLoadingMessages] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [isPeerTyping, setIsPeerTyping] = useState(false);
  const scrollEndRef = useRef<HTMLDivElement | null>(null);
  const typingTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const { t } = useLanguage();
  const { user } = useUser();

  const currentUserId = useMemo<number | null>(() => {
    if (!user) return null;
    const parsed = Number(user.id);
    return Number.isFinite(parsed) ? parsed : null;
  }, [user]);

  const activeConv = useMemo(
    () => conversations.find((conv) => conv.idConversation === selectedConvId) ?? null,
    [conversations, selectedConvId],
  );

  const filteredConversations = useMemo(
    () =>
      conversations.filter((conv) => {
        const name =
          `${conv.prenomAutreUtilisateur ?? ""} ${conv.nomAutreUtilisateur ?? ""}`.trim();
        return name.toLowerCase().includes(searchQuery.toLowerCase());
      }),
    [conversations, searchQuery],
  );

  /** Unread count per conversation (UI derived from local messages cache for active conv only;
   *  for others we show a subtle dot when conv is "recent"). Pure UI heuristic, no API change. */
  const unreadCountByConv = useMemo(() => {
    const map = new Map<number, number>();
    if (selectedConvId !== null) {
      const count = messages.filter((m) => {
        const mine =
          currentUserId !== null ? m.idExpediteur === currentUserId : m.estMonMessage;
        return !mine && !m.est_lu;
      }).length;
      map.set(selectedConvId, count);
    }
    return map;
  }, [messages, selectedConvId, currentUserId]);

  const loadConversations = useCallback(async () => {
    setLoadingConversations(true);
    setError(null);
    try {
      const response = await conversationApi.getMyConversations();
      setConversations(response);
      if (response.length > 0 && selectedConvId === null) {
        setSelectedConvId(response[0].idConversation);
      }
    } catch (err: unknown) {
      setError("Impossible de charger vos conversations.");
      console.error(err);
    } finally {
      setLoadingConversations(false);
    }
  }, [selectedConvId]);

  const markMessagesRead = useCallback(
    async (fetchedMessages: MessageDto[]) => {
      const unreadMessages = fetchedMessages.filter((message) => {
        const isMine =
          currentUserId !== null ? message.idExpediteur === currentUserId : message.estMonMessage;
        return !message.est_lu && !isMine;
      });
      await Promise.all(
        unreadMessages.map(async (message) => {
          try {
            await messageApi.markAsRead(message.idMessage);
          } catch (err: unknown) {
            console.warn("Failed to mark message read", err);
          }
        }),
      );
    },
    [currentUserId],
  );

  const loadMessages = useCallback(
    async (conversationId: number) => {
      setLoadingMessages(true);
      setError(null);
      try {
        const response = await messageApi.getConversationMessages(conversationId);
        setMessages(response);
        await markMessagesRead(response);
        setMessages((current) =>
          current.map((message) => {
            const isMine =
              currentUserId !== null
                ? message.idExpediteur === currentUserId
                : message.estMonMessage;
            return !isMine ? { ...message, est_lu: true } : message;
          }),
        );
      } catch (err: unknown) {
        setError("Impossible de charger les messages.");
        console.error(err);
      } finally {
        setLoadingMessages(false);
      }
    },
    [markMessagesRead, currentUserId],
  );

  useEffect(() => {
    loadConversations();
  }, [loadConversations]);

  useEffect(() => {
    if (selectedConvId !== null) loadMessages(selectedConvId);
  }, [selectedConvId, loadMessages]);

  useEffect(() => {
    scrollEndRef.current?.scrollIntoView({ behavior: "smooth", block: "end" });
  }, [messages, isPeerTyping]);

  useEffect(() => {
    return () => {
      if (typingTimerRef.current) clearTimeout(typingTimerRef.current);
    };
  }, []);

  const contactName = activeConv
    ? `${activeConv.prenomAutreUtilisateur ?? ""} ${activeConv.nomAutreUtilisateur ?? ""}`.trim() ||
      `Conversation ${activeConv.idConversation}`
    : "Conversation";

  const handleSend = async () => {
    const clean = sanitizeText(newMessage).trim();
    if (!clean || selectedConvId === null) return;

    const payload: CreateMessageRequest = {
      idConversation: selectedConvId,
      contenu: clean,
    };

    try {
      await messageApi.sendMessage(payload);
      setNewMessage("");
      await loadMessages(selectedConvId);
      // Simulated peer typing indicator (pure UI — no SignalR wiring yet)
      setIsPeerTyping(true);
      if (typingTimerRef.current) clearTimeout(typingTimerRef.current);
      typingTimerRef.current = setTimeout(() => setIsPeerTyping(false), 2200);
    } catch (err: unknown) {
      console.error("Impossible d'envoyer le message", err);
      setError("Impossible d'envoyer le message.");
    }
  };

  /** Compute a UI status for an outgoing message. Backend only exposes est_lu,
   *  so: read = est_lu; delivered = last sent message not yet read; else sent. */
  const computeStatus = (msg: MessageDto, index: number, list: MessageDto[]): MessageStatus => {
    if (msg.est_lu) return "read";
    // Mark all but the very last outgoing as delivered for nicer UX.
    const isLast = index === list.length - 1;
    return isLast ? "sent" : "delivered";
  };

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      transition={{ duration: 0.3 }}
      className="min-h-screen bg-background flex flex-col"
    >
      <Navbar />
      <main className="flex-1 container py-6 max-w-6xl">
        {error && (
          <div className="mb-3 rounded-lg border border-destructive/30 bg-destructive/10 text-destructive text-sm px-4 py-2">
            {error}
          </div>
        )}
        <div className="bg-card rounded-2xl border border-border shadow-card overflow-hidden flex h-[calc(100vh-200px)] min-h-[520px]">
          {/* Conversations list */}
          <div className="w-full md:w-[340px] border-r border-border flex flex-col shrink-0">
            <motion.div
              className="p-4 border-b border-border"
              initial={{ opacity: 0, y: -10 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.4 }}
            >
              <h2 className="font-heading font-bold text-lg mb-3">{t("messages_title")}</h2>
              <div className="relative">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                <Input
                  placeholder={t("search_messages")}
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="pl-10 rounded-xl bg-muted border-secondary/20"
                />
              </div>
            </motion.div>
            <ScrollArea className="flex-1">
              {loadingConversations ? (
                <div className="p-4 space-y-3">
                  {[0, 1, 2, 3].map((i) => (
                    <div key={i} className="flex items-center gap-3 animate-pulse">
                      <div className="w-12 h-12 rounded-full bg-muted" />
                      <div className="flex-1 space-y-2">
                        <div className="h-3 w-2/3 bg-muted rounded" />
                        <div className="h-3 w-1/2 bg-muted rounded" />
                      </div>
                    </div>
                  ))}
                </div>
              ) : filteredConversations.length === 0 ? (
                <div className="p-6 text-sm text-muted-foreground text-center">
                  Aucune conversation trouvée.
                </div>
              ) : (
                filteredConversations.map((conv, i) => {
                  const name =
                    `${conv.prenomAutreUtilisateur ?? ""} ${conv.nomAutreUtilisateur ?? ""}`.trim() ||
                    `Conversation ${conv.idConversation}`;
                  const time = formatRelative(conv.dateCreation);
                  const isSelected = conv.idConversation === selectedConvId;
                  const unread = unreadCountByConv.get(conv.idConversation) ?? 0;

                  return (
                    <motion.button
                      key={conv.idConversation}
                      onClick={() => setSelectedConvId(conv.idConversation)}
                      className={cn(
                        "w-full flex items-center gap-3 px-4 py-3 hover:bg-muted/50 transition-colors text-left border-l-2 border-transparent",
                        isSelected && "bg-secondary/10 border-primary",
                      )}
                      variants={convItemVariants}
                      initial="hidden"
                      animate="visible"
                      custom={i}
                    >
                      <div className="relative shrink-0">
                        <div className="w-12 h-12 rounded-full bg-gradient-to-br from-primary/20 to-secondary/30 flex items-center justify-center text-primary font-bold">
                          {name.charAt(0).toUpperCase()}
                        </div>
                        <span className="absolute bottom-0 right-0 w-3 h-3 rounded-full bg-green-500 ring-2 ring-card" />
                      </div>
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center justify-between gap-2">
                          <p
                            className={cn(
                              "text-sm truncate",
                              unread > 0 ? "font-bold text-foreground" : "font-semibold",
                            )}
                          >
                            {name}
                          </p>
                          <span className="text-[11px] text-muted-foreground shrink-0">
                            {time}
                          </span>
                        </div>
                        <div className="flex items-center justify-between gap-2 mt-0.5">
                          <p
                            className={cn(
                              "text-xs truncate",
                              unread > 0
                                ? "text-foreground font-medium"
                                : "text-muted-foreground",
                            )}
                          >
                            Cliquez pour ouvrir la conversation
                          </p>
                          {unread > 0 && (
                            <Badge className="h-5 min-w-5 px-1.5 rounded-full bg-primary text-primary-foreground text-[10px] shrink-0">
                              {unread}
                            </Badge>
                          )}
                        </div>
                      </div>
                    </motion.button>
                  );
                })
              )}
            </ScrollArea>
          </div>

          {/* Chat window */}
          <AnimatePresence mode="wait">
            {selectedConvId !== null && activeConv ? (
              <motion.div
                key={selectedConvId}
                className="flex-1 flex flex-col min-w-0"
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
                transition={{ duration: 0.2 }}
              >
                {/* Header */}
                <motion.div
                  className="px-4 py-3 border-b border-border flex items-center gap-3 bg-card"
                  initial={{ opacity: 0, y: -10 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ duration: 0.3 }}
                >
                  <Button
                    variant="ghost"
                    size="icon"
                    className="md:hidden shrink-0"
                    onClick={() => setSelectedConvId(null)}
                  >
                    <ArrowLeft className="h-5 w-5" />
                  </Button>
                  <div className="w-10 h-10 rounded-full bg-gradient-to-br from-primary/20 to-secondary/30 flex items-center justify-center text-primary font-bold shrink-0">
                    {contactName.charAt(0).toUpperCase()}
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="font-semibold text-sm truncate">{contactName}</p>
                    <div className="text-xs text-muted-foreground flex items-center gap-1.5">
                      {isPeerTyping ? (
                        <>
                          <TypingDots />
                          <span className="text-primary">en train d'écrire…</span>
                        </>
                      ) : (
                        <>
                          <span className="w-1.5 h-1.5 rounded-full bg-green-500" />
                          <span>En ligne</span>
                        </>
                      )}
                    </div>
                  </div>
                  <div className="flex gap-1">
                    <Button variant="ghost" size="icon" className="text-muted-foreground hover:text-primary">
                      <Phone className="h-4 w-4" />
                    </Button>
                    <Button variant="ghost" size="icon" className="text-muted-foreground hover:text-primary">
                      <MoreVertical className="h-4 w-4" />
                    </Button>
                  </div>
                </motion.div>

                {/* Contextual ad banner */}
                <motion.div
                  initial={{ opacity: 0, y: -8 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ duration: 0.3, delay: 0.05 }}
                  className="mx-4 mt-3 mb-1 rounded-xl border border-border bg-gradient-to-r from-primary/5 to-secondary/5 p-3 flex items-center gap-3"
                >
                  <div className="w-12 h-12 rounded-lg bg-muted flex items-center justify-center shrink-0">
                    <Tag className="h-5 w-5 text-primary" />
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-xs text-muted-foreground">Annonce concernée</p>
                    <p className="text-sm font-semibold truncate">
                      Discussion #{activeConv.idConversation}
                    </p>
                  </div>
                  <div className="text-right shrink-0">
                    <p className="text-xs text-muted-foreground">Prix</p>
                    <p className="text-sm font-bold text-primary">— DH</p>
                  </div>
                </motion.div>

                {/* Messages */}
                <ScrollArea className="flex-1 px-4 py-3">
                  <div className="space-y-2">
                    {loadingMessages ? (
                      <div className="space-y-3">
                        {[0, 1, 2].map((i) => (
                          <div
                            key={i}
                            className={cn(
                              "flex",
                              i % 2 === 0 ? "justify-start" : "justify-end",
                            )}
                          >
                            <div className="h-10 w-40 rounded-2xl bg-muted animate-pulse" />
                          </div>
                        ))}
                      </div>
                    ) : messages.length === 0 ? (
                      <div className="text-sm text-muted-foreground text-center py-10">
                        Aucun message pour cette conversation.
                      </div>
                    ) : (
                      messages.map((msg, i) => {
                        const isMine =
                          currentUserId !== null
                            ? msg.idExpediteur === currentUserId
                            : Boolean(msg.estMonMessage);
                        const status = computeStatus(msg, i, messages);
                        const prev = messages[i - 1];
                        const prevMine = prev
                          ? currentUserId !== null
                            ? prev.idExpediteur === currentUserId
                            : Boolean(prev.estMonMessage)
                          : null;
                        const groupedWithPrev = prev && prevMine === isMine;

                        return (
                          <motion.div
                            key={msg.idMessage}
                            className={cn(
                              "flex w-full",
                              isMine ? "justify-end" : "justify-start",
                              groupedWithPrev ? "mt-0.5" : "mt-2",
                            )}
                            variants={messageVariants}
                            initial="hidden"
                            animate="visible"
                            custom={isMine}
                          >
                            <div
                              className={cn(
                                "max-w-[75%] px-3.5 py-2 text-sm shadow-sm",
                                isMine
                                  ? "bg-primary text-primary-foreground rounded-2xl rounded-br-md"
                                  : "bg-muted text-foreground rounded-2xl rounded-bl-md",
                              )}
                            >
                              <p className="whitespace-pre-wrap break-words">{msg.contenu}</p>
                              <div
                                className={cn(
                                  "flex items-center gap-1 mt-1 text-[10px]",
                                  isMine
                                    ? "justify-end text-primary-foreground/70"
                                    : "text-muted-foreground",
                                )}
                              >
                                <span>{formatHour(msg.dateEnvoi)}</span>
                                {isMine && <StatusTicks status={status} />}
                              </div>
                            </div>
                          </motion.div>
                        );
                      })
                    )}

                    {isPeerTyping && (
                      <motion.div
                        className="flex justify-start mt-2"
                        initial={{ opacity: 0, y: 6 }}
                        animate={{ opacity: 1, y: 0 }}
                        exit={{ opacity: 0 }}
                      >
                        <div className="bg-muted text-foreground rounded-2xl rounded-bl-md px-4 py-2.5 shadow-sm">
                          <TypingDots />
                        </div>
                      </motion.div>
                    )}
                    <div ref={scrollEndRef} />
                  </div>
                </ScrollArea>

                {/* Composer */}
                <motion.div
                  className="p-3 border-t border-border flex items-center gap-2 bg-card"
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: 0.1 }}
                >
                  <Button
                    variant="ghost"
                    size="icon"
                    className="text-muted-foreground hover:text-primary shrink-0"
                    title="Joindre un fichier"
                  >
                    <Paperclip className="h-5 w-5" />
                  </Button>
                  <Button
                    variant="ghost"
                    size="icon"
                    className="text-muted-foreground hover:text-primary shrink-0"
                    title="Ajouter une image"
                  >
                    <ImageIcon className="h-5 w-5" />
                  </Button>
                  <Input
                    placeholder={t("write_message")}
                    value={newMessage}
                    onChange={(e) => setNewMessage(e.target.value)}
                    onKeyDown={(e) => e.key === "Enter" && handleSend()}
                    maxLength={2000}
                    className="rounded-xl bg-muted border-secondary/20"
                  />
                  <Button
                    variant="ghost"
                    size="icon"
                    className="text-muted-foreground hover:text-primary shrink-0"
                    title="Emoji"
                  >
                    <Smile className="h-5 w-5" />
                  </Button>
                  <motion.div whileHover={{ scale: 1.05 }} whileTap={{ scale: 0.9 }}>
                    <Button
                      onClick={handleSend}
                      size="icon"
                      disabled={!newMessage.trim()}
                      className="bg-primary hover:bg-primary-hover text-primary-foreground rounded-xl shrink-0"
                    >
                      <Send className="h-4 w-4" />
                    </Button>
                  </motion.div>
                </motion.div>
              </motion.div>
            ) : (
              <div className="hidden md:flex flex-1 items-center justify-center text-muted-foreground">
                <motion.p initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ delay: 0.3 }}>
                  {loadingConversations ? "Chargement..." : t("select_conversation")}
                </motion.p>
              </div>
            )}
          </AnimatePresence>
        </div>
      </main>
      <Footer />
    </motion.div>
  );
};

export default Messages;
