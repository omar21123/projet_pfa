import { MessageCircle, X, Send } from "lucide-react";
import { useState } from "react";
import { motion, AnimatePresence } from "framer-motion";

const ChatBot = () => {
  const [isOpen, setIsOpen] = useState(false);
  const [messages, setMessages] = useState<
    { id: number; text: string; sender: "user" | "bot"; timestamp: Date }[]
  >([]);
  const [inputValue, setInputValue] = useState("");

  const suggestedReplies = [
    "Comment publier une annonce?",
    "Questions de sécurité",
    "Support client",
    "Comment ça marche?",
  ];

  const handleSendMessage = (text: string) => {
    if (!text.trim()) return;

    const userMessage = {
      id: messages.length + 1,
      text: text,
      sender: "user" as const,
      timestamp: new Date(),
    };

    setMessages([...messages, userMessage]);
    setInputValue("");

    // Simulate bot response
    setTimeout(() => {
      const botResponses: Record<string, string> = {
        "Comment publier une annonce?":
          "Cliquez sur 'Publier', remplissez les informations et images. Votre annonce sera en ligne immédiatement!",
        "Questions de sécurité":
          "LBAL utilise le chiffrement SSL et les vérifications d'identité pour la sécurité maximale.",
        "Support client":
          "Notre équipe est disponible 24/7. Appelez +212 XXX XXX XXX ou utilisez le chat.",
        "Comment ça marche?":
          "LBAL est un marché en ligne sécurisé pour acheter et vendre au Maroc. Simple et rapide!",
      };

      const response =
        botResponses[text] ||
        "Merci pour votre question! Un agent spécialisé va vous répondre sous peu.";

      const botMessage = {
        id: messages.length + 2,
        text: response,
        sender: "bot" as const,
        timestamp: new Date(),
      };

      setMessages((prev) => [...prev, botMessage]);
    }, 500);
  };

  return (
    <>
      {/* Floating button */}
      <AnimatePresence>
        {!isOpen && (
          <motion.button
            onClick={() => setIsOpen(true)}
            className="fixed bottom-6 right-6 w-14 h-14 rounded-full bg-primary text-primary-foreground shadow-lg flex items-center justify-center z-40 hover:shadow-xl transition-shadow"
            initial={{ scale: 0 }}
            animate={{ scale: 1 }}
            exit={{ scale: 0 }}
            whileHover={{ scale: 1.1 }}
            whileTap={{ scale: 0.95 }}
          >
            <MessageCircle className="h-6 w-6" />
          </motion.button>
        )}
      </AnimatePresence>

      {/* Chat window */}
      <AnimatePresence>
        {isOpen && (
          <motion.div
            className="fixed bottom-6 right-6 w-full max-w-md h-[530px] bg-card rounded-2xl shadow-2xl border border-secondary/20 flex flex-col z-40"
            initial={{ opacity: 0, scale: 0.95, y: 20 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.95, y: 20 }}
            transition={{ duration: 0.2 }}
          >
            {/* Header */}
            <div className="flex items-center justify-between p-4 border-b border-secondary/20">
              <div>
                <h3 className="font-bold">Support LBAL</h3>
                <p className="text-xs text-green-600">En ligne</p>
              </div>
              <motion.button
                onClick={() => setIsOpen(false)}
                className="p-1 hover:bg-secondary/10 rounded-lg transition-colors"
                whileHover={{ scale: 1.1 }}
                whileTap={{ scale: 0.95 }}
              >
                <X className="h-5 w-5" />
              </motion.button>
            </div>

            {/* Messages */}
            <motion.div className="flex-1 overflow-y-auto p-4 space-y-4">
              {messages.map((msg) => (
                <motion.div
                  key={msg.id}
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                  className={`flex ${msg.sender === "user" ? "justify-end" : "justify-start"}`}
                >
                  <div
                    className={`max-w-xs px-4 py-2 rounded-lg ${
                      msg.sender === "user"
                        ? "bg-primary text-primary-foreground rounded-br-none"
                        : "bg-secondary/10 text-foreground rounded-bl-none"
                    }`}
                  >
                    {msg.text}
                  </div>
                </motion.div>
              ))}
            </motion.div>

            {/* Suggested replies */}
            {messages.length === 0 && (
              <motion.div
                className="px-4 py-2 space-y-2"
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
              >
                <p className="text-xs text-muted-foreground">Suggestions:</p>
                <div className="space-y-1">
                  {suggestedReplies.map((reply) => (
                    <motion.button
                      key={reply}
                      onClick={() => handleSendMessage(reply)}
                      className="w-full text-left px-3 py-2 text-sm bg-secondary/5 hover:bg-secondary/15 rounded-lg transition-colors"
                      whileHover={{ paddingLeft: 16 + 4 }}
                    >
                      {reply}
                    </motion.button>
                  ))}
                </div>
              </motion.div>
            )}

            {/* Input */}
            <div className="p-4 border-t border-secondary/20 flex gap-2">
              <input
                type="text"
                value={inputValue}
                onChange={(e) => setInputValue(e.target.value)}
                onKeyPress={(e) => {
                  if (e.key === "Enter") {
                    handleSendMessage(inputValue);
                  }
                }}
                placeholder="Tapez votre message..."
                className="flex-1 px-3 py-2 bg-secondary/5 rounded-lg border border-secondary/20 text-sm focus:outline-none focus:ring-2 focus:ring-primary/30 transition-all"
              />
              <motion.button
                onClick={() => handleSendMessage(inputValue)}
                className="p-2 bg-primary text-primary-foreground rounded-lg hover:bg-primary-hover transition-colors"
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
                disabled={!inputValue.trim()}
              >
                <Send className="h-4 w-4" />
              </motion.button>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </>
  );
};

export default ChatBot;
