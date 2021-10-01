import firebase_admin
from firebase_admin import firestore

# Use the application default credentials
default_app = firebase_admin.initialize_app()

def firestore_add_doc_to_collection(data, collection):
    db = firestore.Client()

    db.collection(collection).add(data)

def init_pickermans():
    firestore_collection = "pickermans"
    init_pickermans = [
        {
            "name": "Mr. Picker",
            "status": "picking",
            "order": 123456
        },
        {
            "name": "Zaza the Great",
            "status": "idle"
        },
        {
            "name": "ClojureMan",
            "status": "idle"
        },
        {
            "name": "Winter Fresh",
            "status": "idle"
        }
    ]
    print("Will initialize pickermans docs in Firestore...")
    print(init_pickermans)
    for x in init_pickermans:
        firestore_add_doc_to_collection(x, firestore_collection)

def main():
    print("Starting to do things...")
    init_pickermans()
    print("Finished succesfully!")


if __name__ == "__main__":
    # execute only if run as a script
    main()