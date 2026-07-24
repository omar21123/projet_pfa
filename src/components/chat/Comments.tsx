import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Send } from "lucide-react";
import StarRating from "@/components/common/StarRating";
import { useLanguage } from "@/contexts/LanguageContext";

interface Comment {
  id: string;
  author: string;
  rating: number;
  text: string;
  date: string;
}

const mockComments: Comment[] = [
  {
    id: "1",
    author: "Fatima Z.",
    rating: 5,
    text: "Vendeur très sérieux, produit conforme à la description. Livraison rapide !",
    date: "Il y a 2 jours",
  },
  {
    id: "2",
    author: "Youssef K.",
    rating: 4,
    text: "Bon état général, petit défaut non mentionné mais rien de grave. Je recommande.",
    date: "Il y a 1 semaine",
  },
  {
    id: "3",
    author: "Sara M.",
    rating: 5,
    text: "Excellente transaction, merci !",
    date: "Il y a 2 semaines",
  },
];

const Comments = () => {
  const { t } = useLanguage();
  const [comments] = useState<Comment[]>(mockComments);
  const [newComment, setNewComment] = useState("");

  return (
    <div className="bg-card rounded-2xl border border-border p-5 shadow-card">
      <h3 className="font-heading font-semibold mb-4">
        {t("reviews")} ({comments.length})
      </h3>
      <div className="space-y-4 mb-5">
        {comments.map((comment) => (
          <div
            key={comment.id}
            className="border-b border-secondary/20 pb-4 last:border-0 last:pb-0"
          >
            <div className="flex items-center justify-between mb-1.5">
              <div className="flex items-center gap-2">
                <div className="w-8 h-8 rounded-full bg-secondary/20 flex items-center justify-center">
                  <span className="text-xs font-bold text-secondary-foreground">
                    {comment.author[0]}
                  </span>
                </div>
                <span className="text-sm font-semibold">{comment.author}</span>
              </div>
              <span className="text-xs text-muted-foreground">{comment.date}</span>
            </div>
            <StarRating rating={comment.rating} size="sm" />
            <p className="text-sm text-muted-foreground mt-1.5 leading-relaxed">{comment.text}</p>
          </div>
        ))}
      </div>
      <div className="flex gap-2">
        <input
          type="text"
          placeholder={t("leave_review")}
          value={newComment}
          onChange={(e) => setNewComment(e.target.value)}
          className="flex-1 h-10 px-4 rounded-xl bg-muted/50 border border-secondary/20 text-sm placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-secondary/30 transition-shadow"
        />
        <Button
          size="icon"
          className="h-10 w-10 rounded-xl bg-primary hover:bg-primary-hover text-primary-foreground"
        >
          <Send className="h-4 w-4" />
        </Button>
      </div>
    </div>
  );
};

export default Comments;
