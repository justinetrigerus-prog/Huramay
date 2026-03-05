from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

# Database Setup
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///users.db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
db = SQLAlchemy(app)

# User Model
class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    full_name = db.Column(db.String(100), nullable=False)
    email = db.Column(db.String(100), unique=True, nullable=False)
    department = db.Column(db.String(100), nullable=False)
    password = db.Column(db.String(100), nullable=False)

# Create Database File
with app.app_context():
    db.create_all()

@app.route('/signup', methods=['POST'])
def signup():
    try:
        data = request.get_json()
        
        # Check if email is already taken
        if User.query.filter_by(email=data['email']).first():
            return jsonify({"message": "Email already registered"}), 400

        new_user = User(
            full_name=data['full_name'],
            email=data['email'],
            department=data['department'],
            password=data['password']
        )
        db.session.add(new_user)
        db.session.commit()
        
        return jsonify({"message": "Registration successful!"}), 201
    except Exception as e:
        return jsonify({"message": "Server Error"}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)