from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
from flask_cors import CORS
from flask_bcrypt import Bcrypt
import os

app = Flask(__name__)
CORS(app)
bcrypt = Bcrypt(app)

# Database Setup
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///User.db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
db = SQLAlchemy(app)

# --- MODELS ---
class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    full_name = db.Column(db.String(100), nullable=False)
    email = db.Column(db.String(100), unique=True, nullable=False)
    department = db.Column(db.String(100), nullable=False)
    password = db.Column(db.String(255), nullable=False)
    photo_path = db.Column(db.String(255), nullable=True, default="")
    rating = db.Column(db.Float, default=5.0) 
    items = db.relationship('Item', backref='owner', lazy=True)

class Item(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(100), nullable=False)
    description = db.Column(db.Text, nullable=False)
    quantity = db.Column(db.Integer, nullable=False, default=1)
    condition = db.Column(db.String(50), nullable=False, default="Good")
    item_image_path = db.Column(db.String(255), nullable=True, default="")
    owner_name = db.Column(db.String(100), nullable=False)
    department = db.Column(db.String(100), nullable=False)
    status = db.Column(db.String(20), default="Available")
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)

with app.app_context():
    db.create_all()

# --- AUTH ROUTES ---
@app.route('/api/register', methods=['POST'])
def register():
    try:
        data = request.get_json()
        if User.query.filter_by(email=data['email']).first():
            return jsonify({"message": "Email already registered"}), 400
        hashed_pass = bcrypt.generate_password_hash(data['password']).decode('utf-8')
        new_user = User(full_name=data['full_name'], email=data['email'], 
                        department=data['department'], password=hashed_pass)
        db.session.add(new_user)
        db.session.commit()
        return jsonify({"message": "Registration successful!"}), 201
    except:
        return jsonify({"message": "Server Error"}), 500

@app.route('/api/login', methods=['POST'])
def login():
    data = request.get_json()
    user = User.query.filter_by(email=data['email']).first()
    if user and bcrypt.check_password_hash(user.password, data['password']):
        return jsonify({
            "id": user.id, "full_name": user.full_name, "email": user.email,               
            "department": user.department, "photo_path": user.photo_path,     
            "rating": user.rating, "message": "Login successful!"
        }), 200
    return jsonify({"message": "Invalid email or password"}), 401

# --- PROFILE ROUTES ---
@app.route('/api/user/update', methods=['POST'])
def update_profile():
    data = request.get_json()
    user = User.query.get(data['id'])
    if user:
        user.photo_path = data.get('photo_path', user.photo_path)
        db.session.commit()
        return jsonify({"message": "Profile updated successfully!"}), 200
    return jsonify({"message": "User not found"}), 404

@app.route('/api/user/reset_password', methods=['POST'])
def reset_password():
    data = request.get_json()
    user = User.query.filter_by(email=data.get('email'), id=data.get('current_user_id')).first()
    if user:
        hashed_pass = bcrypt.generate_password_hash(data['new_password']).decode('utf-8')
        user.password = hashed_pass
        db.session.commit()
        return jsonify({"message": "Password reset successfully!"}), 200
    return jsonify({"message": "Verification failed. You can only reset your own account."}), 403

# --- ITEM ROUTES ---
@app.route('/api/items', methods=['GET', 'POST'])
def handle_items():
    if request.method == 'POST':
        try:
            data = request.get_json()
            new_item = Item(
                title=data['title'], description=data['description'],
                quantity=int(data.get('quantity', 1)), condition=data.get('condition', 'Good'),
                item_image_path=data.get('item_image_path', ''), owner_name=data['owner_name'],
                department=data['department'], user_id=data['user_id']
            )
            db.session.add(new_item)
            db.session.commit()
            return jsonify({"message": "Item posted successfully!"}), 201
        except Exception as e:
            return jsonify({"message": f"Server Error: {str(e)}"}), 500
    
    all_items = Item.query.all()
    return jsonify([_item_to_dict(i) for i in all_items])

@app.route('/api/items/user/<int:user_id>', methods=['GET'])
def get_user_items(user_id):
    items = Item.query.filter_by(user_id=user_id).all()
    return jsonify([_item_to_dict(i) for i in items])

# VAVT-40: UPDATE SPECIFIC ITEM (Now supports image and department)
@app.route('/api/items/<int:item_id>', methods=['PUT'])
def update_item(item_id):
    item = Item.query.get(item_id)
    if not item: return jsonify({"message": "Item not found"}), 404
    data = request.get_json()
    item.title = data.get('title', item.title)
    item.description = data.get('description', item.description)
    item.department = data.get('department', item.department) # VAVT-40 addition
    item.condition = data.get('condition', item.condition)
    item.status = data.get('status', item.status)
    item.item_image_path = data.get('item_image_path', item.item_image_path) # VAVT-40 addition
    db.session.commit()
    return jsonify({"message": "Item updated successfully!"}), 200

@app.route('/api/items/<int:item_id>', methods=['DELETE'])
def delete_item(item_id):
    item = Item.query.get(item_id)
    if not item: return jsonify({"message": "Item not found"}), 404
    db.session.delete(item)
    db.session.commit()
    return jsonify({"message": "Item deleted successfully!"}), 200

def _item_to_dict(i):
    return {
        "id": i.id, "title": i.title, "description": i.description,
        "quantity": i.quantity, "condition": i.condition, "image": i.item_image_path,
        "owner": i.owner_name, "dept": i.department, "status": i.status, "user_id": i.user_id
    }

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)