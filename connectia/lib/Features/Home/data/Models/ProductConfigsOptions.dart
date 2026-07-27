class OptionModel {
  int id;
  String name;

  OptionModel({
    required this.id,
    required this.name,
  });

  factory OptionModel.fromJson(Map<String, dynamic> json) {
    return OptionModel(
      id: json['ID'] as int,
      name: json['Name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ID': id,
      'Name': name,
    };
  }
}

class ProductConfigsOptions {
  int id;
  String name;
  List<OptionModel> options;

  ProductConfigsOptions({
    required this.id,
    required this.name,
    required this.options,
  });

  factory ProductConfigsOptions.fromJson(Map<String, dynamic> json) {
    return ProductConfigsOptions(
      id: json['ID'] as int,
      name: json['Name'] as String,
      options: (json['Options'] as List<dynamic>)
          .map((item) => OptionModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ID': id,
      'Name': name,
      'Options': options.map((option) => option.toJson()).toList(),
    };
  }
}


class ChoosedOptionModel {
  int configID;
  int optionID;

  ChoosedOptionModel({
    required this.configID,
    required this.optionID,
  });

  factory ChoosedOptionModel.fromJson(Map<String, dynamic> json) {
    return ChoosedOptionModel(
      configID: json['configID'] as int,
      optionID: json['optionID'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'configID': configID,
      'optionID': optionID,
    };
  }
}
