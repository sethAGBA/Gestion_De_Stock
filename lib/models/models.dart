import 'dart:convert';

class Variante {
  final String type;
  final String valeur;

  Variante({required this.type, required this.valeur});

  Map<String, dynamic> toMap() => {'type': type, 'valeur': valeur};

  factory Variante.fromMap(Map<String, dynamic> map) {
    return Variante(type: map['type'] as String, valeur: map['valeur'] as String);
  }
}

class Produit {
  final int id;
  final String nom;
  final String? description;
  final String categorie;
  final String? marque;
  final String? imageUrl;
  final String? sku;
  final String? codeBarres;
  final String unite;
  final int quantiteStock;
  final int quantiteAvariee;
  final int stockMin;
  final int stockMax;
  final int seuilAlerte;
  final List<Variante> variantes;
  final double prixAchat;
  final double prixVente;
  final double tva;
  final String? fournisseurPrincipal;
  final List<String> fournisseursSecondaires;
  final DateTime? derniereEntree;
  final DateTime? derniereSortie;
  final String statut;

  Produit({
    required this.id,
    required this.nom,
    this.description,
    required this.categorie,
    this.marque,
    this.imageUrl,
    this.sku,
    this.codeBarres,
    required this.unite,
    required this.quantiteStock,
    required this.quantiteAvariee,
    required this.stockMin,
    required this.stockMax,
    required this.seuilAlerte,
    required this.variantes,
    required this.prixAchat,
    required this.prixVente,
    required this.tva,
    this.fournisseurPrincipal,
    required this.fournisseursSecondaires,
    this.derniereEntree,
    this.derniereSortie,
    required this.statut,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id == 0 ? null : id,
      'nom': nom,
      'description': description,
      'categorie': categorie,
      'marque': marque,
      'imageUrl': imageUrl,
      'sku': sku,
      'codeBarres': codeBarres,
      'unite': unite,
      'quantiteStock': quantiteStock,
      'quantiteAvariee': quantiteAvariee,
      'stockMin': stockMin,
      'stockMax': stockMax,
      'seuilAlerte': seuilAlerte,
      'variantes': jsonEncode(variantes.map((v) => v.toMap()).toList()),
      'prixAchat': prixAchat,
      'prixVente': prixVente,
      'tva': tva,
      'fournisseurPrincipal': fournisseurPrincipal,
      'fournisseursSecondaires': jsonEncode(fournisseursSecondaires),
      'derniereEntree': derniereEntree?.millisecondsSinceEpoch,
      'derniereSortie': derniereSortie?.millisecondsSinceEpoch,
      'statut': statut,
    };
  }

  factory Produit.fromMap(Map<String, dynamic> map) {
    return Produit(
      id: (map['id'] as num?)?.toInt() ?? 0,
      nom: map['nom'] as String? ?? '',
      description: map['description'] as String?,
      categorie: map['categorie'] as String? ?? '',
      marque: map['marque'] as String?,
      imageUrl: map['imageUrl'] as String?,
      sku: map['sku'] as String?,
      codeBarres: map['codeBarres'] as String?,
      unite: map['unite'] as String? ?? '',
      quantiteStock: (map['quantiteStock'] as num?)?.toInt() ?? 0,
      quantiteAvariee: (map['quantiteAvariee'] as num?)?.toInt() ?? 0,
      stockMin: (map['stockMin'] as num?)?.toInt() ?? 0,
      stockMax: (map['stockMax'] as num?)?.toInt() ?? 0,
      seuilAlerte: (map['seuilAlerte'] as num?)?.toInt() ?? 0,
      variantes: (jsonDecode(map['variantes'] as String? ?? '[]') as List<dynamic>)
          .map((v) => Variante.fromMap(v as Map<String, dynamic>))
          .toList(),
      prixAchat: (map['prixAchat'] as num?)?.toDouble() ?? 0.0,
      prixVente: (map['prixVente'] as num?)?.toDouble() ?? 0.0,
      tva: (map['tva'] as num?)?.toDouble() ?? 0.0,
      fournisseurPrincipal: map['fournisseurPrincipal'] as String?,
      fournisseursSecondaires: List<String>.from(jsonDecode(map['fournisseursSecondaires'] as String? ?? '[]')),
      derniereEntree: map['derniereEntree'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['derniereEntree'] as int)
          : null,
      derniereSortie: map['derniereSortie'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['derniereSortie'] as int)
          : null,
      statut: map['statut'] as String? ?? 'disponible',
    );
  }
}

class Supplier {
  final int id;
  final String name;
  final String productName;
  final String category;
  final double price;

  Supplier({
    required this.id,
    required this.name,
    required this.productName,
    required this.category,
    required this.price,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id == 0 ? null : id,
      'name': name,
      'productName': productName,
      'category': category,
      'price': price,
    };
  }

  factory Supplier.fromMap(Map<String, dynamic> map) {
    return Supplier(
      id: (map['id'] as num?)?.toInt() ?? 0,
      name: map['name'] as String? ?? '',
      productName: map['productName'] as String? ?? '',
      category: map['category'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class User {
  final int id;
  final String name;
  final String role;

  User({
    required this.id,
    required this.name,
    required this.role,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id == 0 ? null : id,
      'name': name,
      'role': role,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: (map['id'] as num?)?.toInt() ?? 0,
      name: map['name'] as String? ?? '',
      role: map['role'] as String? ?? '',
    );
  }
}

class Client {
  final int id;
  final String nom;
  final String? email;
  final String? telephone;
  final String? adresse;

  Client({
    required this.id,
    required this.nom,
    this.email,
    this.telephone,
    this.adresse,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id == 0 ? null : id,
      'nom': nom,
      'email': email,
      'telephone': telephone,
      'adresse': adresse,
    };
  }

  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      id: (map['id'] as num?)?.toInt() ?? 0,
      nom: map['nom'] as String? ?? '',
      email: map['email'] as String?,
      telephone: map['telephone'] as String?,
      adresse: map['adresse'] as String?,
    );
  }
}

class BonCommande {
  final int id;
  final int clientId;
  final String? clientNom;
  final DateTime date;
  final String statut;
  final double? total;
  List<BonCommandeItem> items;

  BonCommande({
    required this.id,
    required this.clientId,
    this.clientNom,
    required this.date,
    required this.statut,
    this.total,
    this.items = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id == 0 ? null : id,
      'clientId': clientId,
      'clientNom': clientNom,
      'date': date.millisecondsSinceEpoch,
      'statut': statut,
      'total': total,
    };
  }

  factory BonCommande.fromMap(Map<String, dynamic> map) {
    return BonCommande(
      id: (map['id'] as num?)?.toInt() ?? 0,
      clientId: (map['clientId'] as num?)?.toInt() ?? 0,
      clientNom: map['clientNom'] as String?,
      date: DateTime.fromMillisecondsSinceEpoch((map['date'] as num?)?.toInt() ?? 0),
      statut: map['statut'] as String? ?? 'en attente',
      total: (map['total'] as num?)?.toDouble(),
    );
  }
}

class BonCommandeItem {
  final int id;
  final int bonCommandeId;
  final int produitId;
  String? produitNom;
  final int quantite;
  final double prixUnitaire;

  BonCommandeItem({
    required this.id,
    required this.bonCommandeId,
    required this.produitId,
    this.produitNom,
    required this.quantite,
    required this.prixUnitaire,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id == 0 ? null : id,
      'bonCommandeId': bonCommandeId,
      'produitId': produitId,
      'quantite': quantite,
      'prixUnitaire': prixUnitaire,
    };
  }

  factory BonCommandeItem.fromMap(Map<String, dynamic> map) {
    return BonCommandeItem(
      id: (map['id'] as num?)?.toInt() ?? 0,
      bonCommandeId: (map['bonCommandeId'] as num?)?.toInt() ?? 0,
      produitId: (map['produitId'] as num?)?.toInt() ?? 0,
      quantite: (map['quantite'] as num?)?.toInt() ?? 0,
      prixUnitaire: (map['prixUnitaire'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class Facture {
  final int id;
  final String numero;
  final int bonCommandeId;
  final int clientId;
  String? clientNom;
  final DateTime date;
  final double total;
  final String statutPaiement;

  Facture({
    required this.id,
    required this.numero,
    required this.bonCommandeId,
    required this.clientId,
    this.clientNom,
    required this.date,
    required this.total,
    required this.statutPaiement,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id == 0 ? null : id,
      'numero': numero,
      'bonCommandeId': bonCommandeId,
      'clientId': clientId,
      'date': date.millisecondsSinceEpoch,
      'total': total,
      'statutPaiement': statutPaiement,
    };
  }

  factory Facture.fromMap(Map<String, dynamic> map) {
    return Facture(
      id: (map['id'] as num?)?.toInt() ?? 0,
      numero: map['numero'] as String? ?? '',
      bonCommandeId: (map['bonCommandeId'] as num?)?.toInt() ?? 0,
      clientId: (map['clientId'] as num?)?.toInt() ?? 0,
      date: DateTime.fromMillisecondsSinceEpoch((map['date'] as num?)?.toInt() ?? 0),
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
      statutPaiement: map['statutPaiement'] as String? ?? 'en attente',
    );
  }
}

class Paiement {
  final int id;
  final int factureId;
  final double montant;
  final DateTime date;
  final String methode;

  Paiement({
    required this.id,
    required this.factureId,
    required this.montant,
    required this.date,
    required this.methode,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id == 0 ? null : id,
      'factureId': factureId,
      'montant': montant,
      'date': date.millisecondsSinceEpoch,
      'methode': methode,
    };
  }

  factory Paiement.fromMap(Map<String, dynamic> map) {
    return Paiement(
      id: (map['id'] as num?)?.toInt() ?? 0,
      factureId: (map['factureId'] as num?)?.toInt() ?? 0,
      montant: (map['montant'] as num?)?.toDouble() ?? 0.0,
      date: DateTime.fromMillisecondsSinceEpoch((map['date'] as num?)?.toInt() ?? 0),
      methode: map['methode'] as String? ?? '',
    );
  }
}

class DamagedAction {
  final int id;
  final int produitId;
  final String produitNom;
  final int quantite;
  final String action;
  final String utilisateur;
  final int date;

  DamagedAction({
    required this.id,
    required this.produitId,
    required this.produitNom,
    required this.quantite,
    required this.action,
    required this.utilisateur,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id == 0 ? null : id,
      'produitId': produitId,
      'produitNom': produitNom,
      'quantite': quantite,
      'action': action,
      'utilisateur': utilisateur,
      'date': date,
    };
  }

  factory DamagedAction.fromMap(Map<String, dynamic> map) {
    return DamagedAction(
      id: (map['id'] as num?)?.toInt() ?? 0,
      produitId: (map['produitId'] as num?)?.toInt() ?? 0,
      produitNom: map['produitNom'] as String? ?? 'Inconnu',
      quantite: (map['quantite'] as num?)?.toInt() ?? 0,
      action: map['action'] as String? ?? '',
      utilisateur: map['utilisateur'] as String? ?? '',
      date: (map['date'] as num?)?.toInt() ?? 0,
    );
  }
}