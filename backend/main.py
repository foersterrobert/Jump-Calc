import os
import random
from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy.sql import func

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///db.sqlite3'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
db = SQLAlchemy(app)

class Game(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    started = False
    questions = None
    
    def __repr__(self):
        return f"Game(id={self.id})"
    
class Player(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(80), nullable=False)
    score = db.Column(db.Integer, default=0)
    game_id = db.Column(db.Integer, db.ForeignKey('game.id'), nullable=False)

    def __repr__(self):
        return f"Player(id={self.id}, name={self.name}, score={self.score})"

@app.route('/game/<player_name>', methods=['POST'])
def create_game(player_name):
    while True:
        game_id = random.randint(1000, 9999)
        if Game.query.filter_by(id=game_id).first() is None:
            break
    game = Game(id=game_id, players=0, questions=0, state=0)

    while True:
        player_id = random.randint(1000, 9999)
        if Player.query.filter_by(id=player_id).first() is None:
            break
    player = Player(id=player_id, name=player_name, game_id=game_id)
    
    db.session.add(game)
    db.session.add(player)
    db.session.commit()
    return {
        "game_id": game.id,
        "player_id": player.id
    }

@app.route('/game/<int:game_id>/<player_name>', methods=['POST'])
def join_game(game_id, player_name):
    game = Game.query.filter_by(id=game_id).first()
    if game is None:
        return {
            "error": "game not found"
        }, 404
    
    while True:
        player_id = random.randint(1000, 9999)
        if Player.query.filter_by(id=player_id).first() is None:
            break

    player = Player(id=player_id, name=player_name, game_id=game_id)
    
    db.session.add(player)
    db.session.commit()
    return {
        "game_id": game.id,
        "player_id": player.id
    }

@app.route('/game/<int:game_id>/start', methods=['POST'])
def start_game(game_id):
    game = Game.query.filter_by(id=game_id).first()
    if game is None:
        return {
            "error": "game not found"
        }, 404
    game.started = True
    db.session.commit()
    return {
        "game_id": game.id
    }

@app.route('/game/<int:game_id>/questions', methods=['GET'])
def get_questions(game_id):
    game = Game.query.filter_by(id=game_id).first()
    if game is None:
        return {
            "error": "game not found"
        }, 404
    return {
        "game_id": game.id,
        "questions": game.questions
    }

# state of a game
@app.route('/game/<int:game_id>/state', methods=['GET'])
def get_state(game_id):
    game = Game.query.filter_by(id=game_id).first()
    if game is None:
        return {
            "error": "game not found"
        }, 404
    return {
        "game_id": game.id,
        "players": game.players,
        "questions": game.questions,
        "state": game.state
    }

if __name__ == '__main__':
    app.run(host="0.0.0.0", port=50001)