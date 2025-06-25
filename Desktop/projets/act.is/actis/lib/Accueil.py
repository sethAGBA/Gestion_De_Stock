from PySide6.QtWidgets import (QApplication, QMainWindow, QWidget, QVBoxLayout, QLabel, QMessageBox)
from PySide6.QtGui import QAction
from Achat import PurchaseForm
from Vente import VenteForm
from Stock_Entree import StockEntreeForm
import sqlite3
import sys

class WelcomeWindow(QMainWindow):
       def __init__(self):
           super().__init__()
           self.setWindowTitle("Formulaire d'Accueil - Gestion")
           self.setGeometry(100, 100, 600, 400)

           # Création du widget central et du layout
           central_widget = QWidget()
           self.setCentralWidget(central_widget)
           layout = QVBoxLayout(central_widget)
           
           # Message d'accueil
           self.welcome_label = QLabel("Bienvenue dans l'application de gestion")
           self.welcome_label.setStyleSheet("font-size: 16px; font-weight: bold;")
           layout.addWidget(self.welcome_label)
           
           # Création de la barre de menus
           self.create_menu_bar()

       def create_menu_bar(self):
           menubar = self.menuBar()
           
           # Menu Fichier
           file_menu = menubar.addMenu("Fichier")
           disconnect_action = QAction("Se déconnecter", self)
           disconnect_action.triggered.connect(self.disconnect)
           file_menu.addAction(disconnect_action)
           
           change_user_action = QAction("Changer d'utilisateur", self)
           change_user_action.triggered.connect(self.change_user)
           file_menu.addAction(change_user_action)
           
           exit_action = QAction("Quitter", self)
           exit_action.triggered.connect(self.close)
           file_menu.addAction(exit_action)
           
           # Menu Opération
           operation_menu = menubar.addMenu("Opération")
           
           purchase_action = QAction("Achat", self)
           purchase_action.triggered.connect(self.perform_purchase)
           operation_menu.addAction(purchase_action)
           
           sale_action = QAction("Vente", self)
           sale_action.triggered.connect(self.perform_sale)
           operation_menu.addAction(sale_action)
           
           # Sous-menu Gestion de stock
           stock_menu = operation_menu.addMenu("Gestion de stock")
           stock_entry_action = QAction("Entrée", self)
           stock_entry_action.triggered.connect(self.stock_entry)
           stock_menu.addAction(stock_entry_action)
           
           stock_exit_action = QAction("Sortie", self)
           stock_exit_action.triggered.connect(self.stock_exit)
           stock_menu.addAction(stock_exit_action)
           
           # Menu Afficher
           display_menu = menubar.addMenu("Afficher")
           purchase_list_action = QAction("Liste des achats", self)
           purchase_list_action.triggered.connect(self.show_purchase_list)
           display_menu.addAction(purchase_list_action)
           
           sale_list_action = QAction("Liste des ventes", self)
           sale_list_action.triggered.connect(self.show_sale_list)
           display_menu.addAction(sale_list_action)
           
           stock_sheet_action = QAction("Fiche de stock", self)
           stock_sheet_action.triggered.connect(self.show_stock_sheet)
           display_menu.addAction(stock_sheet_action)
           
           # Menu Paramètres
           settings_menu = menubar.addMenu("Paramètres")
           user_action = QAction("Utilisateur", self)
           user_action.triggered.connect(self.manage_users)
           settings_menu.addAction(user_action)
           
           # Menu Aide
           help_menu = menubar.addMenu("Aide")
           help_action = QAction("Aide", self)
           help_action.triggered.connect(self.show_help)
           help_menu.addAction(help_action)

       # Fonctions des actions
       def disconnect(self):
           QMessageBox.information(self, "Déconnexion", "Vous avez été déconnecté.")
           
       def change_user(self):
           QMessageBox.information(self, "Changer d'utilisateur", "Changement d'utilisateur en cours.")
           
       def perform_purchase(self):
           purchase_form = PurchaseForm(self)
           if purchase_form.exec():
               pass
           
       def perform_sale(self):
           sale_form = VenteForm(self)
           if sale_form.exec():
               pass
           
       def stock_entry(self):
           entry_form = StockEntreeForm(self)
           if entry_form.exec():
               pass
           
       def stock_exit(self):
           QMessageBox.information(self, "Sortie de stock", "Enregistrement d'une sortie de stock.")
           
       def show_purchase_list(self):
           QMessageBox.information(self, "Liste des achats", "Affichage de la liste des achats.")
           
       def show_sale_list(self):
           QMessageBox.information(self, "Liste des ventes", "Affichage de la liste des ventes.")
           
       def show_stock_sheet(self):
           QMessageBox.information(self, "Fiche de stock", "Affichage de la fiche de stock.")
           
           def manage_users(self):
               QMessageBox.information(self, "Paramètres utilisateur", "Gestion des utilisateurs.")
    
           def show_help(self):
               QMessageBox.information(self, "Aide", "Documentation et aide de l'application.")
    
           if __name__ == "__main__":  
            app = QApplication(sys.argv)
            window = WelcomeWindow()
            window.show()
            sys.exit(app.exec())