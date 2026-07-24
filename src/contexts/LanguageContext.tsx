import React, { createContext, useContext, useState, useCallback } from "react";

export type Language = "fr" | "en" | "ar";

type Translations = Record<string, Record<Language, string>>;

const translations: Translations = {
  // Navbar
  search_placeholder: {
    fr: "Rechercher sur LBAL...",
    en: "Search on LBAL...",
    ar: "...البحث في LBAL",
  },
  search_type_ads: { fr: "Articles", en: "Articles", ar: "الإعلانات" },
  search_type_members: { fr: "Membres", en: "Members", ar: "الأعضاء" },
  search_ads_placeholder: {
    fr: "Rechercher des articles",
    en: "Search articles",
    ar: "ابحث عن إعلانات",
  },
  search_members_placeholder: {
    fr: "Rechercher des membres",
    en: "Search members",
    ar: "ابحث عن أعضاء",
  },
  publish: { fr: "Publier", en: "Publish", ar: "نشر" },
  login: { fr: "Se connecter", en: "Log in", ar: "تسجيل الدخول" },
  cart: { fr: "Panier", en: "Cart", ar: "السلة" },
  favorites: { fr: "Mes favoris", en: "My favorites", ar: "المفضلة" },
  messages: { fr: "Messages", en: "Messages", ar: "الرسائل" },
  dashboard: { fr: "Tableau de bord", en: "Dashboard", ar: "لوحة التحكم" },
  profile: { fr: "Profil", en: "Profile", ar: "الملف الشخصي" },
  settings: { fr: "Paramètres", en: "Settings", ar: "الإعدادات" },
  logout: { fr: "Se déconnecter", en: "Log out", ar: "تسجيل الخروج" },
  hello: { fr: "Bonjour", en: "Hello", ar: "مرحبا" },
  notifications: { fr: "Notifications", en: "Notifications", ar: "الإشعارات" },

  // Hero
  hero_title: {
    fr: "Trouvez tout près de chez vous",
    en: "Find everything near you",
    ar: "ابحث عن كل شيء بالقرب منك",
  },
  hero_subtitle: {
    fr: "Achetez et vendez facilement partout au Maroc",
    en: "Buy and sell easily across Morocco",
    ar: "اشترِ وبِع بسهولة في جميع أنحاء المغرب",
  },
  hero_search_placeholder: {
    fr: "Que cherchez-vous ?",
    en: "What are you looking for?",
    ar: "ماذا تبحث عنه؟",
  },
  all_cities: { fr: "Toutes les villes", en: "All cities", ar: "جميع المدن" },
  search: { fr: "Rechercher", en: "Search", ar: "بحث" },
  voice_search: { fr: "Recherche vocale", en: "Voice search", ar: "بحث صوتي" },
  popular_suggestions: {
    fr: "Suggestions populaires",
    en: "Popular suggestions",
    ar: "اقتراحات شائعة",
  },

  // Featured Ads
  featured_ads: {
    fr: "Annonces vedettes",
    en: "Featured Ads",
    ar: "إعلانات مميزة",
  },
  new: { fr: "Nouveau", en: "New", ar: "جديد" },
  view_ad: { fr: "Voir l'annonce", en: "View ad", ar: "عرض الإعلان" },

  // Ads Grid
  recent_ads: {
    fr: "Annonces récentes",
    en: "Recent Ads",
    ar: "إعلانات حديثة",
  },
  filters: { fr: "Filtres", en: "Filters", ar: "الفلاتر" },
  view_all: { fr: "Voir tout →", en: "View all →", ar: "← عرض الكل" },
  clear_all: { fr: "Tout effacer", en: "Clear all", ar: "مسح الكل" },
  no_ads_found: {
    fr: "Aucune annonce trouvée",
    en: "No ads found",
    ar: "لم يتم العثور على إعلانات",
  },
  try_different_criteria: {
    fr: "Essayez de modifier vos critères de recherche",
    en: "Try changing your search criteria",
    ar: "حاول تغيير معايير البحث",
  },
  reset_filters: {
    fr: "Réinitialiser les filtres",
    en: "Reset filters",
    ar: "إعادة ضبط الفلاتر",
  },

  // Ad Card
  add_to_cart: {
    fr: "Ajouter au panier",
    en: "Add to cart",
    ar: "أضف إلى السلة",
  },
  added_to_cart_title: { fr: "Panier", en: "Cart", ar: "السلة" },
  added_to_cart_msg: {
    fr: "Le produit a été ajouté au panier",
    en: "Product added to cart",
    ar: "تمت إضافة المنتج إلى السلة",
  },
  seller: { fr: "Vendeur", en: "Seller", ar: "البائع" },

  // Filter Sidebar
  budget: { fr: "Budget", en: "Budget", ar: "الميزانية" },
  categories: { fr: "Catégories", en: "Categories", ar: "الفئات" },
  cities: { fr: "Villes", en: "Cities", ar: "المدن" },
  period: { fr: "Période", en: "Period", ar: "الفترة" },
  start_date: { fr: "Date de début", en: "Start date", ar: "تاريخ البداية" },
  end_date: { fr: "Date de fin", en: "End date", ar: "تاريخ النهاية" },
  apply_filters: {
    fr: "Appliquer les filtres",
    en: "Apply filters",
    ar: "تطبيق الفلاتر",
  },
  reset: { fr: "Réinitialiser", en: "Reset", ar: "إعادة ضبط" },

  // How It Works
  how_it_works: {
    fr: "Comment ça marche?",
    en: "How does it work?",
    ar: "كيف يعمل؟",
  },
  how_it_works_subtitle: {
    fr: "Suivez ces 4 étapes simples pour commencer à acheter ou vendre sur LBAL",
    en: "Follow these 4 simple steps to start buying or selling on LBAL",
    ar: "اتبع هذه الخطوات الأربع البسيطة للبدء في الشراء أو البيع على LBAL",
  },
  step_search: { fr: "Recherchez", en: "Search", ar: "ابحث" },
  step_search_desc: {
    fr: "Trouvez exactement ce que vous cherchez avec nos filtres avancés",
    en: "Find exactly what you're looking for with our advanced filters",
    ar: "ابحث بالضبط عما تريده باستخدام الفلاتر المتقدمة",
  },
  step_contact: { fr: "Contactez", en: "Contact", ar: "تواصل" },
  step_contact_desc: {
    fr: "Discutez directement avec les vendeurs pour négocier les prix",
    en: "Chat directly with sellers to negotiate prices",
    ar: "تحدث مباشرة مع البائعين للتفاوض على الأسعار",
  },
  step_review: { fr: "Consultez", en: "Review", ar: "راجع" },
  step_review_desc: {
    fr: "Consultez les évaluations et la sécurité pour chaque vendeur",
    en: "Check ratings and safety for each seller",
    ar: "راجع التقييمات والأمان لكل بائع",
  },
  step_secure: { fr: "Sécurisez", en: "Secure", ar: "أمّن" },
  step_secure_desc: {
    fr: "Effectuez des transactions sûres avec nos services de paiement",
    en: "Make safe transactions with our payment services",
    ar: "قم بمعاملات آمنة مع خدمات الدفع لدينا",
  },
  start_now: { fr: "Commencer maintenant", en: "Start now", ar: "ابدأ الآن" },

  // Testimonials
  testimonials_title: {
    fr: "Témoignages de nos utilisateurs",
    en: "User testimonials",
    ar: "شهادات المستخدمين",
  },

  // Stats
  stats_title: {
    fr: "MARCHÉ en chiffres",
    en: "MARCHÉ in numbers",
    ar: "MARCHÉ بالأرقام",
  },
  active_users: {
    fr: "Utilisateurs actifs",
    en: "Active users",
    ar: "مستخدمون نشطون",
  },
  daily_ads: {
    fr: "Annonces quotidiennes",
    en: "Daily ads",
    ar: "إعلانات يومية",
  },
  safe_transactions: {
    fr: "Transactions sûres",
    en: "Safe transactions",
    ar: "معاملات آمنة",
  },
  cities_covered: {
    fr: "Villes couvertes",
    en: "Cities covered",
    ar: "مدن مغطاة",
  },

  // FAQ
  faq_title: {
    fr: "Questions fréquemment posées",
    en: "Frequently asked questions",
    ar: "الأسئلة الشائعة",
  },
  faq_subtitle: {
    fr: "Trouvez les réponses à vos questions sur LBAL",
    en: "Find answers to your questions about LBAL",
    ar: "ابحث عن إجابات لأسئلتك حول LBAL",
  },
  faq_q1: {
    fr: "Comment puis-je publier une annonce?",
    en: "How can I publish an ad?",
    ar: "كيف يمكنني نشر إعلان؟",
  },
  faq_a1: {
    fr: "Cliquez sur 'Publier' en haut à droite, remplissez les informations et sélectionnez les images. Votre annonce sera publiée immédiatement.",
    en: "Click 'Publish' at the top right, fill in the information and select images. Your ad will be published immediately.",
    ar: "انقر على 'نشر' في أعلى اليمين، واملأ المعلومات واختر الصور. سيتم نشر إعلانك على الفور.",
  },
  faq_q2: {
    fr: "Combien de temps une annonce reste-t-elle active?",
    en: "How long does an ad stay active?",
    ar: "كم من الوقت يبقى الإعلان نشطاً؟",
  },
  faq_a2: {
    fr: "Une annonce reste active pendant 30 jours. Vous pouvez la renouveler gratuitement pour une autre période.",
    en: "An ad stays active for 30 days. You can renew it for free for another period.",
    ar: "يبقى الإعلان نشطاً لمدة 30 يوماً. يمكنك تجديده مجاناً لفترة أخرى.",
  },
  faq_q3: {
    fr: "Comment je peux payer en sécurité?",
    en: "How can I pay securely?",
    ar: "كيف يمكنني الدفع بأمان؟",
  },
  faq_a3: {
    fr: "LBAL propose plusieurs méthodes de paiement sécurisées: carte bancaire, virement, Maroc Telecom Money, Orange Money et Wallet.",
    en: "LBAL offers several secure payment methods: bank card, transfer, Maroc Telecom Money, Orange Money and Wallet.",
    ar: "يقدم LBAL عدة طرق دفع آمنة: بطاقة بنكية، تحويل، Maroc Telecom Money، Orange Money و Wallet.",
  },
  faq_q4: {
    fr: "Que faire si j'ai un problème avec un achat?",
    en: "What to do if I have a problem with a purchase?",
    ar: "ماذا أفعل إذا واجهت مشكلة في عملية شراء؟",
  },
  faq_a4: {
    fr: "Contactez notre support client 24/7 via le chat. Nous médiatisons les litiges et protégeons vos intérêts.",
    en: "Contact our 24/7 customer support via chat. We mediate disputes and protect your interests.",
    ar: "تواصل مع دعم العملاء على مدار الساعة عبر الدردشة. نحن نتوسط في النزاعات ونحمي مصالحك.",
  },
  faq_q5: {
    fr: "Est-ce gratuit de publier une annonce?",
    en: "Is it free to publish an ad?",
    ar: "هل نشر الإعلان مجاني؟",
  },
  faq_a5: {
    fr: "Oui! Les annonces basiques sont 100% gratuites. Des options premium sont disponibles pour plus de visibilité.",
    en: "Yes! Basic ads are 100% free. Premium options are available for more visibility.",
    ar: "نعم! الإعلانات الأساسية مجانية 100%. تتوفر خيارات مميزة لمزيد من الظهور.",
  },
  no_answer: {
    fr: "Vous n'avez pas trouvé votre réponse?",
    en: "Didn't find your answer?",
    ar: "لم تجد إجابتك؟",
  },
  contact_support: {
    fr: "Contactez le support",
    en: "Contact support",
    ar: "تواصل مع الدعم",
  },

  // Footer
  footer_desc: {
    fr: "La plateforme de confiance pour acheter et vendre au Maroc",
    en: "The trusted platform to buy and sell in Morocco",
    ar: "المنصة الموثوقة للشراء والبيع في المغرب",
  },
  about: { fr: "À propos", en: "About", ar: "حول" },
  careers: { fr: "Carrières", en: "Careers", ar: "وظائف" },
  blog: { fr: "Blog", en: "Blog", ar: "مدونة" },
  press: { fr: "Presse", en: "Press", ar: "صحافة" },
  help_center: { fr: "Centre d'aide", en: "Help center", ar: "مركز المساعدة" },
  contact: { fr: "Contact", en: "Contact", ar: "اتصل بنا" },
  faq: { fr: "FAQ", en: "FAQ", ar: "الأسئلة الشائعة" },
  community: { fr: "Communauté", en: "Community", ar: "مجتمع" },
  terms: { fr: "Conditions", en: "Terms", ar: "الشروط" },
  privacy: { fr: "Confidentialité", en: "Privacy", ar: "الخصوصية" },
  cookies: { fr: "Cookies", en: "Cookies", ar: "ملفات تعريف الارتباط" },
  legal_notices: {
    fr: "Mentions légales",
    en: "Legal notices",
    ar: "إشعارات قانونية",
  },
  secured: { fr: "Sécurisé", en: "Secured", ar: "آمن" },
  encrypted: { fr: "Chiffré", en: "Encrypted", ar: "مشفر" },
  fast: { fr: "Rapide", en: "Fast", ar: "سريع" },
  newsletter: { fr: "Newsletter", en: "Newsletter", ar: "النشرة الإخبارية" },
  newsletter_desc: {
    fr: "Recevez les meilleures annonces directement dans votre boîte mail",
    en: "Get the best ads directly in your inbox",
    ar: "احصل على أفضل الإعلانات مباشرة في بريدك",
  },
  your_email: { fr: "Votre email", en: "Your email", ar: "بريدك الإلكتروني" },
  subscribe: { fr: "S'abonner", en: "Subscribe", ar: "اشتراك" },
  all_rights: {
    fr: "Tous droits réservés.",
    en: "All rights reserved.",
    ar: "جميع الحقوق محفوظة.",
  },
  made_with_love: { fr: "Fait avec", en: "Made with", ar: "صُنع بـ" },
  in_morocco: { fr: "au Maroc", en: "in Morocco", ar: "في المغرب" },
  company: { fr: "Entreprise", en: "Company", ar: "الشركة" },
  support: { fr: "Support", en: "Support", ar: "الدعم" },
  legal: { fr: "Légal", en: "Legal", ar: "قانوني" },

  // Ad Details
  back: { fr: "Retour", en: "Back", ar: "رجوع" },
  description: { fr: "Description", en: "Description", ar: "الوصف" },
  contact_seller: { fr: "Contacter", en: "Contact", ar: "تواصل" },

  // Comments
  reviews: { fr: "Avis", en: "Reviews", ar: "تقييمات" },
  leave_review: {
    fr: "Laisser un avis...",
    en: "Leave a review...",
    ar: "...اترك تقييماً",
  },

  // Cart
  your_cart_empty: {
    fr: "Votre panier est vide",
    en: "Your cart is empty",
    ar: "سلتك فارغة",
  },
  explore_ads: {
    fr: "Explorez nos annonces et ajoutez des articles à votre panier",
    en: "Explore our ads and add items to your cart",
    ar: "استكشف إعلاناتنا وأضف عناصر إلى سلتك",
  },
  continue_shopping: {
    fr: "Continuer le shopping",
    en: "Continue shopping",
    ar: "متابعة التسوق",
  },
  my_cart: { fr: "Mon Panier", en: "My Cart", ar: "سلتي" },
  items_in_cart: {
    fr: "article(s) dans votre panier",
    en: "item(s) in your cart",
    ar: "عنصر(عناصر) في سلتك",
  },
  subtotal: { fr: "Sous-total", en: "Subtotal", ar: "المجموع الفرعي" },
  delivery: { fr: "Livraison", en: "Delivery", ar: "التوصيل" },
  free: { fr: "Gratuite", en: "Free", ar: "مجاني" },
  taxes: { fr: "Taxes", en: "Taxes", ar: "الضرائب" },
  total: { fr: "Total", en: "Total", ar: "المجموع" },
  summary: { fr: "Résumé", en: "Summary", ar: "ملخص" },
  proceed_payment: {
    fr: "Procéder au paiement",
    en: "Proceed to payment",
    ar: "المتابعة للدفع",
  },

  // Category Nav
  cat_vehicles: { fr: "Véhicules", en: "Vehicles", ar: "مركبات" },
  cat_real_estate: { fr: "Immobilier", en: "Real Estate", ar: "عقارات" },
  cat_phones: { fr: "Téléphones", en: "Phones", ar: "هواتف" },
  cat_computers: { fr: "Informatique", en: "Computers", ar: "حواسيب" },
  cat_fashion: { fr: "Mode", en: "Fashion", ar: "أزياء" },
  cat_home: { fr: "Maison", en: "Home", ar: "منزل" },
  cat_sports: { fr: "Sports", en: "Sports", ar: "رياضة" },
  cat_jobs: { fr: "Emploi", en: "Jobs", ar: "وظائف" },
  cat_trending: { fr: "Tendances", en: "Trending", ar: "رائج" },

  // Login
  login_title: {
    fr: "Connectez-vous à votre compte",
    en: "Log in to your account",
    ar: "تسجيل الدخول إلى حسابك",
  },
  register_title: {
    fr: "Créer un nouveau compte",
    en: "Create a new account",
    ar: "إنشاء حساب جديد",
  },
  nom: { fr: "Nom", en: "Last name", ar: "الاسم العائلي" },
  prenom: { fr: "Prénom", en: "First name", ar: "الاسم الشخصي" },
  telephone: { fr: "Téléphone", en: "Phone number", ar: "رقم الهاتف" },
  nom_placeholder: { fr: "Votre nom", en: "Your last name", ar: "اسمك العائلي" },
  prenom_placeholder: { fr: "Votre prénom", en: "Your first name", ar: "اسمك الشخصي" },
  telephone_placeholder: { fr: "Votre numéro", en: "Your phone number", ar: "رقم هاتفك" },
  email: { fr: "Email", en: "Email", ar: "البريد الإلكتروني" },
  password: { fr: "Mot de passe", en: "Password", ar: "كلمة المرور" },
  sign_in: { fr: "Se connecter", en: "Log in", ar: "تسجيل الدخول" },
  sign_up: { fr: "S'inscrire", en: "Sign up", ar: "إنشاء حساب" },
  already_have_account: {
    fr: "Déjà un compte ?",
    en: "Already have an account?",
    ar: "لديك حساب بالفعل؟",
  },
  no_account: {
    fr: "Pas encore de compte ?",
    en: "Don't have an account?",
    ar: "ليس لديك حساب؟",
  },
  fill_all_fields: {
    fr: "Veuillez remplir tous les champs",
    en: "Please fill in all fields",
    ar: "يرجى ملء جميع الحقول",
  },
  invalid_email: {
    fr: "Veuillez entrer un email valide",
    en: "Please enter a valid email",
    ar: "يرجى إدخال بريد إلكتروني صالح",
  },
  password_min: {
    fr: "Le mot de passe doit contenir au moins 6 caractères",
    en: "Password must be at least 6 characters",
    ar: "يجب أن تحتوي كلمة المرور على 6 أحرف على الأقل",
  },
  verification_note: {
    fr: "Lors de l'inscription, vous recevrez un code de vérification par email.",
    en: "Upon registration, you will receive a verification code by email.",
    ar: "عند التسجيل، ستتلقى رمز التحقق عبر البريد الإلكتروني.",
  },

  // Profile
  my_profile: { fr: "Mon Profil", en: "My Profile", ar: "ملفي الشخصي" },
  back_to_home: { fr: "Retour", en: "Back", ar: "رجوع" },
  name: { fr: "Nom", en: "Name", ar: "الاسم" },
  edit_settings: {
    fr: "Modifier les paramètres",
    en: "Edit settings",
    ar: "تعديل الإعدادات",
  },

  // Settings
  settings_title: { fr: "Paramètres", en: "Settings", ar: "الإعدادات" },
  back_to_profile: {
    fr: "Retour au profil",
    en: "Back to profile",
    ar: "العودة إلى الملف الشخصي",
  },
  email_no_edit: {
    fr: "L'email ne peut pas être modifié",
    en: "Email cannot be changed",
    ar: "لا يمكن تغيير البريد الإلكتروني",
  },
  save_changes: {
    fr: "Enregistrer les modifications",
    en: "Save changes",
    ar: "حفظ التغييرات",
  },
  cancel: { fr: "Annuler", en: "Cancel", ar: "إلغاء" },
  settings_saved: {
    fr: "Paramètres sauvegardés avec succès!",
    en: "Settings saved successfully!",
    ar: "تم حفظ الإعدادات بنجاح!",
  },

  // Messages
  messages_title: { fr: "Messages", en: "Messages", ar: "الرسائل" },
  search_messages: { fr: "Rechercher...", en: "Search...", ar: "بحث..." },
  write_message: {
    fr: "Écrire un message...",
    en: "Write a message...",
    ar: "اكتب رسالة...",
  },
  select_conversation: {
    fr: "Sélectionnez une conversation",
    en: "Select a conversation",
    ar: "اختر محادثة",
  },

  // Favorites
  my_favorites: { fr: "Mes Favoris", en: "My Favorites", ar: "مفضلاتي" },
  saved_ads: {
    fr: "annonces sauvegardées",
    en: "saved ads",
    ar: "إعلانات محفوظة",
  },
  search_favorites: {
    fr: "Rechercher dans vos favoris...",
    en: "Search your favorites...",
    ar: "ابحث في مفضلاتك...",
  },
  added_to_favorites: {
    fr: "Ajouter aux favoris",
    en: "Add to favorites",
    ar: "إضافة إلى المفضلة",
  },
  removed_from_favorites: {
    fr: "Retirer des favoris",
    en: "Remove from favorites",
    ar: "إزالة من المفضلة",
  },
  no_favorites: {
    fr: "Aucun favori trouvé",
    en: "No favorites found",
    ar: "لم يتم العثور على مفضلات",
  },

  // Create Ad
  create_ad_title: {
    fr: "Publier une annonce",
    en: "Publish an ad",
    ar: "نشر إعلان",
  },
  photos_max: {
    fr: "Photos (max 6)",
    en: "Photos (max 6)",
    ar: "صور (بحد أقصى 6)",
  },
  add_photo: { fr: "Ajouter", en: "Add", ar: "إضافة" },
  title: { fr: "Titre", en: "Title", ar: "العنوان" },
  title_placeholder: {
    fr: "Ex: iPhone 15 Pro Max",
    en: "E.g.: iPhone 15 Pro Max",
    ar: "مثال: iPhone 15 Pro Max",
  },
  description_label: { fr: "Description", en: "Description", ar: "الوصف" },
  description_placeholder: {
    fr: "Décrivez votre article...",
    en: "Describe your item...",
    ar: "صف منتجك...",
  },
  price_dh: { fr: "Prix (DH)", en: "Price (DH)", ar: "السعر (درهم)" },
  category: { fr: "Catégorie", en: "Category", ar: "الفئة" },
  choose: { fr: "Choisir", en: "Choose", ar: "اختر" },
  city: { fr: "Ville", en: "City", ar: "المدينة" },
  marque: { fr: "Marque", en: "Brand", ar: "العلامة التجارية" },
  color: { fr: "Couleur", en: "Color", ar: "اللون" },
  condition: { fr: "État", en: "Condition", ar: "الحالة" },
  publish_ad: { fr: "Publier l'annonce", en: "Publish ad", ar: "نشر الإعلان" },

  // Conditions — clés aplaties : "condition_<id>"
  condition_new_with_tags: {
    fr: "Neuf avec étiquette",
    en: "New with tags",
    ar: "جديد مع بطاقة",
  },
  condition_new_without_tags: {
    fr: "Neuf sans étiquette",
    en: "New without tags",
    ar: "جديد بدون بطاقة",
  },
  condition_very_good: {
    fr: "Très bon état",
    en: "Very good condition",
    ar: "حالة جيدة جدا",
  },
  condition_good: {
    fr: "Bon état",
    en: "Good condition",
    ar: "حالة جيدة",
  },
  condition_acceptable: {
    fr: "État acceptable",
    en: "Acceptable condition",
    ar: "حالة مقبولة",
  },
  condition_used: {
    fr: "Occasion",
    en: "Used",
    ar: "مستعمل",
  },

  // Colors — clés aplaties : "color_<id>"
  color_black: { fr: "Noir", en: "Black", ar: "أسود" },
  color_white: { fr: "Blanc", en: "White", ar: "أبيض" },
  color_red: { fr: "Rouge", en: "Red", ar: "أحمر" },
  color_blue: { fr: "Bleu", en: "Blue", ar: "أزرق" },
  color_green: { fr: "Vert", en: "Green", ar: "أخضر" },
  color_yellow: { fr: "Jaune", en: "Yellow", ar: "أصفر" },
  color_gray: { fr: "Gris", en: "Gray", ar: "رمادي" },
  color_brown: { fr: "Marron", en: "Brown", ar: "بني" },
  color_beige: { fr: "Beige", en: "Beige", ar: "بيج" },

  // User Dashboard
  my_ads: { fr: "Mes annonces", en: "My ads", ar: "إعلاناتي" },
  edit: { fr: "Modifier", en: "Edit", ar: "تعديل" },
  member_since: { fr: "Membre depuis", en: "Member since", ar: "عضو منذ" },
  sold: { fr: "Vendu", en: "Sold", ar: "مُباع" },

  // NotFound
  page_not_found: {
    fr: "Oops! Page introuvable",
    en: "Oops! Page not found",
    ar: "عذراً! الصفحة غير موجودة",
  },
  return_home: {
    fr: "Retour à l'accueil",
    en: "Return to Home",
    ar: "العودة للرئيسية",
  },

  // Verify Email
  verify_email_title: {
    fr: "Vérification de l'email",
    en: "Email Verification",
    ar: "التحقق من البريد الإلكتروني",
  },
};

interface LanguageContextType {
  language: Language;
  setLanguage: (lang: Language) => void;
  t: (key: string) => string;
  dir: "ltr" | "rtl";
}

const LanguageContext = createContext<LanguageContextType | undefined>(undefined);

export const LanguageProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [language, setLanguageState] = useState<Language>(() => {
    const saved = localStorage.getItem("language") as Language;
    return saved || "fr";
  });

  const setLanguage = useCallback((lang: Language) => {
    setLanguageState(lang);
    localStorage.setItem("language", lang);
    document.documentElement.dir = lang === "ar" ? "rtl" : "ltr";
    document.documentElement.lang = lang;
  }, []);

  const t = useCallback(
    (key: string): string => {
      return translations[key]?.[language] || key;
    },
    [language],
  );

  const dir = language === "ar" ? "rtl" : "ltr";

  React.useEffect(() => {
    document.documentElement.dir = dir;
    document.documentElement.lang = language;
  }, [language, dir]);

  return (
    <LanguageContext.Provider value={{ language, setLanguage, t, dir }}>
      {children}
    </LanguageContext.Provider>
  );
};

// eslint-disable-next-line react-refresh/only-export-components
export const useLanguage = (): LanguageContextType => {
  const context = useContext(LanguageContext);
  if (!context) {
    throw new Error("useLanguage must be used within LanguageProvider");
  }
  return context;
};
