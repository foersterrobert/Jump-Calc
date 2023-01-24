import os
import random
from flask import Flask
from flask_restful import Api, Resource, reqparse, abort
from flask_sqlalchemy import SQLAlchemy

app = Flask(__name__)
api = Api(app)
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///database.db'
db = SQLAlchemy(app)

class Game(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    started = db.Column(db.Boolean, default=False)
    
    def __repr__(self):
        return f"Game(id={self.id})"
    
class Player(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(80), nullable=False)
    score = db.Column(db.Integer, default=0)

    game_id = db.Column(db.Integer, db.ForeignKey('game.id'))
    game = db.relationship("Game", backref=db.backref("game", uselist=False))

    def __repr__(self):
        return f"Player(id={self.id}, name={self.name}, score={self.score})"
    
class GameResource(Resource):
    ### Create Game
    def post(self, player_name):
        while True:
            game_id = random.randint(1000, 9999)
            if Game.query.filter_by(id=game_id).first() is None:
                break
        game = Game(id=game_id)

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
    
    ### Join Game
    def put(self, game_id, player_name):
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
    
    ### Start Game
    def path(self, game_id):
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
    
    ### Get Game
    def get(self, game_id):
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


class PlayerResource(Resource):
    ### Get Questions
    def get(self, game_id):
        return {
            "questions": []
        }
    
    ### Answer Question
    def put(self, player_id, answer):
        return {
            "answer": answer
        }

api.add_resource(GameResource, "/game/<int:game_id>", "/game/<string:player_name>")
api.add_resource(PlayerResource, "/game/<int:game_id>/player/<int:player_id>", "/game/<int:game_id>/player/<int:player_id>/<string:answer>")

if __name__ == '__main__':
    app.run()