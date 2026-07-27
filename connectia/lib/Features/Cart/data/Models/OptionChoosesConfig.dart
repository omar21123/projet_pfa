/// Un choix de configuration déjà sélectionné, affiché en lecture seule
/// (ex: dans un résumé panier / commande).
class OptionChoosesConfig {
  final String configName;
  final String optionName;

  const OptionChoosesConfig({
    required this.configName,
    required this.optionName,
  });
}