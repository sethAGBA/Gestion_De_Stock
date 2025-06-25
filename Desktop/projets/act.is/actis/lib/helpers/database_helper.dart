

// import 'package:flutter/material.dart';
// import 'package:sqflite/sqflite.dart';
// import 'package:path/path.dart';

// class DatabaseHelper {
//   static final DatabaseHelper _instance = DatabaseHelper._internal();
//   factory DatabaseHelper() => _instance;
//   DatabaseHelper._internal();

//   Database? _database;
//   static const int _databaseVersion = 8; // Incrémenté pour corriger la migration

//   Future<Database> get database async {
//     if (_database != null) return _database!;
//     _database = await _initDatabase();
//     return _database!;
//   }

//   Future<Database> _initDatabase() async {
//     String path = join(await getDatabasesPath(), 'actis_clients.db');
//     try {
//       debugPrint('Opening database at path: $path');
//       return await openDatabase(
//         path,
//         version: _databaseVersion,
//         onCreate: (db, version) async {
//           debugPrint('Creating database with version $version');
//           await db.execute('''
//             CREATE TABLE clients (
//               id INTEGER PRIMARY KEY AUTOINCREMENT,
//               clientType TEXT,
//               gender TEXT,
//               services TEXT,
//               name TEXT,
//               phone TEXT,
//               email TEXT,
//               address TEXT,
//               notes TEXT,
//               profession TEXT,
//               birthdate TEXT,
//               height REAL,
//               weight REAL,
//               neck REAL,
//               chest REAL,
//               waist REAL,
//               hips REAL,
//               shoulder REAL,
//               armLength REAL,
//               bustLength REAL,
//               totalLength REAL,
//               armCircumference REAL,
//               wrist REAL,
//               inseam REAL,
//               pantLength REAL,
//               thigh REAL,
//               knee REAL,
//               ankle REAL,
//               buttocks REAL,
//               underBust REAL,
//               bustDistance REAL,
//               bustHeight REAL,
//               skirtLength REAL,
//               dressLength REAL,
//               calf REAL,
//               heelHeight REAL,
//               backBustLength REAL,
//               headCircumference REAL,
//               photo TEXT,
//               deliveryDate TEXT,
//               createdAt TEXT,
//               status TEXT,
//               measurements TEXT,
//               imagePath TEXT
//             )
//           ''');
//           await db.execute('''
//             CREATE TABLE orders (
//               id INTEGER PRIMARY KEY AUTOINCREMENT,
//               clientId INTEGER,
//               service TEXT,
//               amount REAL,
//               amountPaid REAL,
//               remainingBalance REAL,
//               deliveryDate TEXT,
//               orderDate TEXT,
//               status TEXT,
//               FOREIGN KEY (clientId) REFERENCES clients(id)
//             )
//           ''');
//           await db.execute('''
//             CREATE TABLE settings (
//               id INTEGER PRIMARY KEY AUTOINCREMENT,
//               businessName TEXT,
//               businessAddress TEXT,
//               businessPhone TEXT,
//               businessEmail TEXT,
//               businessLogoPath TEXT
//             )
//           ''');
//           await db.insert('settings', {
//             'businessName': 'Actis Couture',
//             'businessAddress': '123 Rue de la Mode, Ville',
//             'businessPhone': '+1234567890',
//             'businessEmail': 'contact@actiscouture.com',
//             'businessLogoPath': ''
//           });
//         },
//         onUpgrade: (db, oldVersion, newVersion) async {
//           debugPrint('Upgrading database from version $oldVersion to $newVersion');
//           if (oldVersion < 2) {
//             await db.execute('ALTER TABLE clients ADD COLUMN imagePath TEXT');
//           }
//           if (oldVersion < 3) {
//             await db.execute('ALTER TABLE orders ADD COLUMN clientId INTEGER');
//             await db.execute('UPDATE orders SET clientId = 0 WHERE clientId IS NULL');
//           }
//           if (oldVersion < 4) {
//             await db.execute('''
//               CREATE TABLE settings (
//                 id INTEGER PRIMARY KEY AUTOINCREMENT,
//                 businessName TEXT,
//                 businessAddress TEXT,
//                 businessPhone TEXT,
//                 businessEmail TEXT,
//                 businessLogoPath TEXT
//               )
//             ''');
//             await db.insert('settings', {
//               'businessName': 'Actis Couture',
//               'businessAddress': '123 Rue de la Mode, Ville',
//               'businessPhone': '+1234567890',
//               'businessEmail': 'contact@actiscouture.com',
//               'businessLogoPath': ''
//             });
//           }
//           if (oldVersion < 5) {
//             final columnsToAdd = [
//               'clientType TEXT',
//               'gender TEXT',
//               'email TEXT',
//               'notes TEXT',
//               'profession TEXT',
//               'birthdate TEXT',
//               'height REAL',
//               'weight REAL',
//               'neck REAL',
//               'chest REAL',
//               'waist REAL',
//               'hips REAL',
//               'shoulder REAL',
//               'armLength REAL',
//               'bustLength REAL',
//               'totalLength REAL',
//               'armCircumference REAL',
//               'wrist REAL',
//               'inseam REAL',
//               'pantLength REAL',
//               'thigh REAL',
//               'knee REAL',
//               'ankle REAL',
//               'buttocks REAL',
//               'underBust REAL',
//               'bustDistance REAL',
//               'bustHeight REAL',
//               'skirtLength REAL',
//               'dressLength REAL',
//               'calf REAL',
//               'heelHeight REAL',
//               'backBustLength REAL',
//               'headCircumference REAL',
//               'photo TEXT',
//               'deliveryDate TEXT',
//               'createdAt TEXT',
//               'status TEXT'
//             ];
//             for (var column in columnsToAdd) {
//               await db.execute('ALTER TABLE clients ADD COLUMN $column');
//             }
//           }
//           if (oldVersion < 6) {
//             await db.execute('''
//               CREATE TABLE clients_new (
//                 id INTEGER PRIMARY KEY AUTOINCREMENT,
//                 clientType TEXT,
//                 gender TEXT,
//                 services TEXT,
//                 name TEXT,
//                 phone TEXT,
//                 email TEXT,
//                 address TEXT,
//                 notes TEXT,
//                 profession TEXT,
//                 birthdate TEXT,
//                 height REAL,
//                 weight REAL,
//                 neck REAL,
//                 chest REAL,
//                 waist REAL,
//                 hips REAL,
//                 shoulder REAL,
//                 armLength REAL,
//                 bustLength REAL,
//                 totalLength REAL,
//                 armCircumference REAL,
//                 wrist REAL,
//                 inseam REAL,
//                 pantLength REAL,
//                 thigh REAL,
//                 knee REAL,
//                 ankle REAL,
//                 buttocks REAL,
//                 underBust REAL,
//                 bustDistance REAL,
//                 bustHeight REAL,
//                 skirtLength REAL,
//                 dressLength REAL,
//                 calf REAL,
//                 heelHeight REAL,
//                 backBustLength REAL,
//                 headCircumference REAL,
//                 photo TEXT,
//                 deliveryDate TEXT,
//                 createdAt TEXT,
//                 status TEXT,
//                 measurements TEXT,
//                 imagePath TEXT
//               )
//             ''');
//             await db.execute('''
//               INSERT INTO clients_new (id, name, phone, services, measurements, imagePath)
//               SELECT id, name, phone, services, measurements, imagePath FROM clients
//             ''');
//             await db.execute('DROP TABLE clients');
//             await db.execute('ALTER TABLE clients_new RENAME TO clients');
//           }
//           if (oldVersion < 7) {
//             // Migration pour ajouter les jointures dans getOrders (aucune modification de structure)
//           }
//           if (oldVersion < 8) {
//             // Migration vide pour corriger l'erreur précédente
//           }
//         },
//       );
//     } catch (e) {
//       debugPrint('Error opening database: $e');
//       rethrow;
//     }
//   }

//   Future<int> insertClient(Map<String, dynamic> client) async {
//     final db = await database;
//     return await db.transaction((txn) async {
//       return await txn.insert('clients', client, conflictAlgorithm: ConflictAlgorithm.replace);
//     });
//   }

//   Future<List<Map<String, dynamic>>> getClients() async {
//     final db = await database;
//     return await db.query('clients');
//   }

//   Future<Map<String, dynamic>?> getClient(int id) async {
//     final db = await database;
//     final List<Map<String, dynamic>> maps = await db.query(
//       'clients',
//       where: 'id = ?',
//       whereArgs: [id],
//     );
//     return maps.isNotEmpty ? maps.first : null;
//   }

//   Future<int> updateClient(Map<String, dynamic> client) async {
//     final db = await database;
//     return await db.transaction((txn) async {
//       return await txn.update(
//         'clients',
//         client,
//         where: 'id = ?',
//         whereArgs: [client['id']],
//       );
//     });
//   }

//   Future<int> deleteClient(int id) async {
//     final db = await database;
//     return await db.transaction((txn) async {
//       await txn.delete('orders', where: 'clientId = ?', whereArgs: [id]);
//       return await txn.delete('clients', where: 'id = ?', whereArgs: [id]);
//     });
//   }

//   Future<int> insertOrder(Map<String, dynamic> order) async {
//     final db = await database;
//     final orderCopy = Map<String, dynamic>.from(order);
//     orderCopy.remove('id'); // Supprimer l'id pour permettre l'auto-incrémentation
//     debugPrint('Inserting order: $orderCopy');
//     return await db.transaction((txn) async {
//       return await txn.insert('orders', orderCopy, conflictAlgorithm: ConflictAlgorithm.replace);
//     });
//   }

//   Future<List<Map<String, dynamic>>> getOrders() async {
//     final db = await database;
//     final orders = await db.rawQuery('''
//       SELECT orders.*, clients.name AS clientName
//       FROM orders
//       LEFT JOIN clients ON orders.clientId = clients.id
//     ''');
//     debugPrint('Loaded orders: $orders');
//     return orders;
//   }

//   Future<List<Map<String, dynamic>>> getOrdersForClient(int clientId) async {
//     final db = await database;
//     final orders = await db.rawQuery('''
//       SELECT orders.*, clients.name AS clientName
//       FROM orders
//       LEFT JOIN clients ON orders.clientId = clients.id
//       WHERE orders.clientId = ?
//     ''', [clientId]);
//     debugPrint('Loaded orders for client $clientId: $orders');
//     return orders;
//   }

//   Future<int> updateOrder(Map<String, dynamic> order) async {
//     final db = await database;
//     return await db.transaction((txn) async {
//       return await txn.update(
//         'orders',
//         order,
//         where: 'id = ?',
//         whereArgs: [order['id']],
//       );
//     });
//   }

//   Future<int> deleteOrder(int id) async {
//     final db = await database;
//     return await db.transaction((txn) async {
//       return await txn.delete('orders', where: 'id = ?', whereArgs: [id]);
//     });
//   }

//   Future<Map<String, dynamic>?> getSettings() async {
//     final db = await database;
//     try {
//       final List<Map<String, dynamic>> maps = await db.query('settings', limit: 1);
//       if (maps.isEmpty) {
//         await db.insert('settings', {
//           'businessName': 'Actis Couture',
//           'businessAddress': '123 Rue de la Mode, Ville',
//           'businessPhone': '+1234567890',
//           'businessEmail': 'contact@actiscouture.com',
//           'businessLogoPath': ''
//         });
//         final newMaps = await db.query('settings', limit: 1);
//         return newMaps.isNotEmpty ? newMaps.first : null;
//       }
//       return maps.first;
//     } catch (e) {
//       debugPrint('Error in getSettings: $e');
//       rethrow;
//     }
//   }

//   Future<int> updateSettings(Map<String, dynamic> settings) async {
//     final db = await database;
//     try {
//       return await db.transaction((txn) async {
//         final count = await txn.update(
//           'settings',
//           settings,
//           where: 'id = ?',
//           whereArgs: [settings['id']],
//         );
//         if (count == 0) {
//           return await txn.insert('settings', settings);
//         }
//         return count;
//       });
//     } catch (e) {
//       debugPrint('Error in updateSettings: $e');
//       rethrow;
//     }
//   }
// }







import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Database? _database;
  static const int _databaseVersion = 8; // Incrémenté pour corriger la migration

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'actis_clients.db');
    try {
      debugPrint('Opening database at path: $path');
      return await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: (db, version) async {
          debugPrint('Creating database with version $version');
          await db.execute('''
            CREATE TABLE clients (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              clientType TEXT,
              gender TEXT,
              services TEXT,
              name TEXT,
              phone TEXT,
              email TEXT,
              address TEXT,
              notes TEXT,
              profession TEXT,
              birthdate TEXT,
              height REAL,
              weight REAL,
              neck REAL,
              chest REAL,
              waist REAL,
              hips REAL,
              shoulder REAL,
              armLength REAL,
              bustLength REAL,
              totalLength REAL,
              armCircumference REAL,
              wrist REAL,
              inseam REAL,
              pantLength REAL,
              thigh REAL,
              knee REAL,
              ankle REAL,
              buttocks REAL,
              underBust REAL,
              bustDistance REAL,
              bustHeight REAL,
              skirtLength REAL,
              dressLength REAL,
              calf REAL,
              heelHeight REAL,
              backBustLength REAL,
              headCircumference REAL,
              photo TEXT,
              deliveryDate TEXT,
              createdAt TEXT,
              status TEXT,
              measurements TEXT,
              imagePath TEXT
            )
          ''');
          await db.execute('''
            CREATE TABLE orders (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              clientId INTEGER,
              service TEXT,
              amount REAL,
              amountPaid REAL,
              remainingBalance REAL,
              deliveryDate TEXT,
              orderDate TEXT,
              status TEXT,
              FOREIGN KEY (clientId) REFERENCES clients(id)
            )
          ''');
          await db.execute('''
            CREATE TABLE settings (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              businessName TEXT,
              businessAddress TEXT,
              businessPhone TEXT,
              businessEmail TEXT,
              businessLogoPath TEXT
            )
          ''');
          await db.insert('settings', {
            'businessName': 'Actis Couture',
            'businessAddress': '123 Rue de la Mode, Ville',
            'businessPhone': '+1234567890',
            'businessEmail': 'contact@actiscouture.com',
            'businessLogoPath': ''
          });
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          debugPrint('Upgrading database from version $oldVersion to $newVersion');
          if (oldVersion < 2) {
            await db.execute('ALTER TABLE clients ADD COLUMN imagePath TEXT');
          }
          if (oldVersion < 3) {
            await db.execute('ALTER TABLE orders ADD COLUMN clientId INTEGER');
            await db.execute('UPDATE orders SET clientId = 0 WHERE clientId IS NULL');
          }
          if (oldVersion < 4) {
            await db.execute('''
              CREATE TABLE settings (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                businessName TEXT,
                businessAddress TEXT,
                businessPhone TEXT,
                businessEmail TEXT,
                businessLogoPath TEXT
              )
            ''');
            await db.insert('settings', {
              'businessName': 'Actis Couture',
              'businessAddress': '123 Rue de la Mode, Ville',
              'businessPhone': '+1234567890',
              'businessEmail': 'contact@actiscouture.com',
              'businessLogoPath': ''
            });
          }
          if (oldVersion < 5) {
            final columnsToAdd = [
              'clientType TEXT',
              'gender TEXT',
              'email TEXT',
              'notes TEXT',
              'profession TEXT',
              'birthdate TEXT',
              'height REAL',
              'weight REAL',
              'neck REAL',
              'chest REAL',
              'waist REAL',
              'hips REAL',
              'shoulder REAL',
              'armLength REAL',
              'bustLength REAL',
              'totalLength REAL',
              'armCircumference REAL',
              'wrist REAL',
              'inseam REAL',
              'pantLength REAL',
              'thigh REAL',
              'knee REAL',
              'ankle REAL',
              'buttocks REAL',
              'underBust REAL',
              'bustDistance REAL',
              'bustHeight REAL',
              'skirtLength REAL',
              'dressLength REAL',
              'calf REAL',
              'heelHeight REAL',
              'backBustLength REAL',
              'headCircumference REAL',
              'photo TEXT',
              'deliveryDate TEXT',
              'createdAt TEXT',
              'status TEXT'
            ];
            for (var column in columnsToAdd) {
              await db.execute('ALTER TABLE clients ADD COLUMN $column');
            }
          }
          if (oldVersion < 6) {
            await db.execute('''
              CREATE TABLE clients_new (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                clientType TEXT,
                gender TEXT,
                services TEXT,
                name TEXT,
                phone TEXT,
                email TEXT,
                address TEXT,
                notes TEXT,
                profession TEXT,
                birthdate TEXT,
                height REAL,
                weight REAL,
                neck REAL,
                chest REAL,
                waist REAL,
                hips REAL,
                shoulder REAL,
                armLength REAL,
                bustLength REAL,
                totalLength REAL,
                armCircumference REAL,
                wrist REAL,
                inseam REAL,
                pantLength REAL,
                thigh REAL,
                knee REAL,
                ankle REAL,
                buttocks REAL,
                underBust REAL,
                bustDistance REAL,
                bustHeight REAL,
                skirtLength REAL,
                dressLength REAL,
                calf REAL,
                heelHeight REAL,
                backBustLength REAL,
                headCircumference REAL,
                photo TEXT,
                deliveryDate TEXT,
                createdAt TEXT,
                status TEXT,
                measurements TEXT,
                imagePath TEXT
              )
            ''');
            await db.execute('''
              INSERT INTO clients_new (id, name, phone, services, measurements, imagePath)
              SELECT id, name, phone, services, measurements, imagePath FROM clients
            ''');
            await db.execute('DROP TABLE clients');
            await db.execute('ALTER TABLE clients_new RENAME TO clients');
          }
          if (oldVersion < 7) {
            // Migration pour ajouter les jointures dans getOrders (aucune modification de structure)
          }
          if (oldVersion < 8) {
            // Migration vide pour corriger l'erreur précédente
          }
        },
      );
    } catch (e) {
      debugPrint('Error opening database: $e');
      rethrow;
    }
  }

  Future<int> insertClient(Map<String, dynamic> client) async {
    final db = await database;
    return await db.transaction((txn) async {
      return await txn.insert('clients', client, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  Future<List<Map<String, dynamic>>> getClients() async {
    final db = await database;
    return await db.query('clients');
  }

  Future<Map<String, dynamic>?> getClient(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'clients',
      where: 'id = ?',
      whereArgs: [id],
    );
    return maps.isNotEmpty ? maps.first : null;
  }

  Future<int> updateClient(Map<String, dynamic> client) async {
    final db = await database;
    return await db.transaction((txn) async {
      return await txn.update(
        'clients',
        client,
        where: 'id = ?',
        whereArgs: [client['id']],
      );
    });
  }

  Future<int> deleteClient(int id) async {
    final db = await database;
    return await db.transaction((txn) async {
      await txn.delete('orders', where: 'clientId = ?', whereArgs: [id]);
      return await txn.delete('clients', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<int> insertOrder(Map<String, dynamic> order) async {
    final db = await database;
    final orderCopy = Map<String, dynamic>.from(order);
    orderCopy.remove('id'); // Supprimer l'id pour permettre l'auto-incrémentation
    debugPrint('Inserting order: $orderCopy');
    return await db.transaction((txn) async {
      return await txn.insert('orders', orderCopy, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  Future<List<Map<String, dynamic>>> getOrders() async {
    final db = await database;
    final orders = await db.rawQuery('''
      SELECT orders.*, clients.name AS clientName
      FROM orders
      LEFT JOIN clients ON orders.clientId = clients.id
    ''');
    debugPrint('Loaded orders: $orders');
    return orders;
  }

  Future<List<Map<String, dynamic>>> getOrdersForClient(int clientId) async {
    final db = await database;
    final orders = await db.rawQuery('''
      SELECT orders.*, clients.name AS clientName
      FROM orders
      LEFT JOIN clients ON orders.clientId = clients.id
      WHERE orders.clientId = ?
    ''', [clientId]);
    debugPrint('Loaded orders for client $clientId: $orders');
    return orders;
  }

  Future<int> updateOrder(Map<String, dynamic> order) async {
    final db = await database;
    return await db.transaction((txn) async {
      return await txn.update(
        'orders',
        order,
        where: 'id = ?',
        whereArgs: [order['id']],
      );
    });
  }

  Future<int> deleteOrder(int id) async {
    final db = await database;
    return await db.transaction((txn) async {
      return await txn.delete('orders', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<Map<String, dynamic>?> getSettings() async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query('settings', limit: 1);
      if (maps.isEmpty) {
        await db.insert('settings', {
          'businessName': 'Actis Couture',
          'businessAddress': '123 Rue de la Mode, Ville',
          'businessPhone': '+1234567890',
          'businessEmail': 'contact@actiscouture.com',
          'businessLogoPath': ''
        });
        final newMaps = await db.query('settings', limit: 1);
        return newMaps.isNotEmpty ? newMaps.first : null;
      }
      return maps.first;
    } catch (e) {
      debugPrint('Error in getSettings: $e');
      rethrow;
    }
  }

  Future<int> updateSettings(Map<String, dynamic> settings) async {
    final db = await database;
    try {
      return await db.transaction((txn) async {
        final count = await txn.update(
          'settings',
          settings,
          where: 'id = ?',
          whereArgs: [settings['id']],
        );
        if (count == 0) {
          return await txn.insert('settings', settings);
        }
        return count;
      });
    } catch (e) {
      debugPrint('Error in updateSettings: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getUpcomingBirthdays() async {
    final db = await database;
    final now = DateTime.now();
    final thirtyDaysLater = now.add(const Duration(days: 30));
    final List<Map<String, dynamic>> clients = await db.query('clients', where: 'birthdate IS NOT NULL AND birthdate != ""');
    final List<Map<String, dynamic>> upcoming = [];

    for (final client in clients) {
      final birthdateStr = client['birthdate'].toString().trim();
      if (birthdateStr.isEmpty) continue;

      DateTime? birthdate;
      try {
        // Try standard YYYY-MM-DD format
        birthdate = DateTime.parse(birthdateStr);
      } catch (e) {
        // Try DD/MM/YYYY or DD/M/YYYY format
        try {
          final formatter = DateFormat('dd/MM/yyyy');
          birthdate = formatter.parseStrict(birthdateStr.replaceAll(RegExp(r'\s+'), ''));
        } catch (e) {
          try {
            final formatter = DateFormat('dd/M/yyyy');
            birthdate = formatter.parseStrict(birthdateStr.replaceAll(RegExp(r'\s+'), ''));
          } catch (e) {
            debugPrint('Error parsing birthdate for client ${client['name']}: $e, birthdate: $birthdateStr');
            continue;
          }
        }
      }

      try {
        var nextBirthday = DateTime(now.year, birthdate.month, birthdate.day);
        if (nextBirthday.isBefore(now) || nextBirthday.isAtSameMomentAs(now)) {
          nextBirthday = DateTime(now.year + 1, birthdate.month, birthdate.day);
        }
        if (nextBirthday.isBefore(thirtyDaysLater) || nextBirthday.isAtSameMomentAs(thirtyDaysLater)) {
          final daysUntil = nextBirthday.difference(now).inDays;
          final clientWithDays = Map<String, dynamic>.from(client);
          clientWithDays['daysUntil'] = daysUntil;
          upcoming.add(clientWithDays);
        }
      } catch (e) {
        debugPrint('Error calculating birthday for client ${client['name']}: $e');
      }
    }
    debugPrint('Upcoming birthdays: $upcoming');
    return upcoming;
  }

  Future<List<Map<String, dynamic>>> getUpcomingOrders() async {
    final db = await database;
    final now = DateTime.now();
    final sevenDaysLater = now.add(const Duration(days: 7));
    final List<Map<String, dynamic>> orders = await db.query('orders', where: 'deliveryDate IS NOT NULL');
    final List<Map<String, dynamic>> upcoming = [];

    for (final order in orders) {
      try {
        final deliveryDate = DateTime.parse(order['deliveryDate']);
        if ((deliveryDate.isAfter(now) || deliveryDate.isAtSameMomentAs(now)) &&
            (deliveryDate.isBefore(sevenDaysLater) || deliveryDate.isAtSameMomentAs(sevenDaysLater))) {
          upcoming.add(order);
        }
      } catch (e) {
        debugPrint('Error parsing deliveryDate for order: $e');
      }
    }
    debugPrint('Upcoming orders: $upcoming');
    return upcoming;
  }

  Future<Map<String, dynamic>?> getClientById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'clients',
      where: 'id = ?',
      whereArgs: [id],
    );
    debugPrint('Client with id $id: ${maps.isNotEmpty ? maps.first : null}');
    return maps.isNotEmpty ? maps.first : null;
  }
}
