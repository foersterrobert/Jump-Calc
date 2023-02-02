import os
import random
from flask import Flask
from flask_restful import Api, Resource, reqparse, abort
from flask_sqlalchemy import SQLAlchemy
import requests

app = Flask(__name__)
api = Api(app)
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///database.db'
db = SQLAlchemy(app)

# def generate_questions():
#     questions = []
#     for i in range(10):
#         question = {
#             "question": "Question {}".format(i),
#             "answers": ["Answer {}".format(i) for i in range(4)],
#             "correct": random.randint(0, 3)
                                                            
#         }
#         questions.append(question)
#     return questions

class Game(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    started = db.Column(db.Boolean, default=False)
    # questions = db.Column(db.JSON, default=[])
    
    def __repr__(self):
        return f"Game(id={self.id})"
    
class Player(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(80), nullable=False)
    score = db.Column(db.Integer, default=0)
    alive = db.Column(db.Boolean, default=True)

    game_id = db.Column(db.Integer, db.ForeignKey('game.id'))
    game = db.relationship("Game", backref=db.backref("game", uselist=False))

    def __repr__(self):
        return f"Player(id={self.id}, name={self.name}, score={self.score})"

class GameResource(Resource):
    ### Create Game
    def post(self, game_id, player_name):
        while True:
            game_id = random.randint(1000, 9999)
            if Game.query.filter_by(id=game_id).first() is None:
                break
        game = Game(id=game_id) #questions=generate_questions())

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
    def path(self, game_id, player_name):
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
    def get(self, game_id, player_name):
        game = Game.query.filter_by(id=game_id).first()
        if game is None:
            return {
                "error": "game not found"
            }, 404
        return {
            "game_id": game.id,
            # "players": game.players,
            # "questions": game.questions,
            # "state": game.state
        }


class PlayerResource(Resource):
    ### Get Questions
    def get(self, game_id, player_id, answer):
        game = Game.query.filter_by(id=game_id).first()
        if game is None:
            return {
                "error": "game not found"
            }, 404
        return {
            "questions": game.questions
        }

    ### Answer Question
    def put(self, game_id, player_id, answer):
        player = Player.query.filter_by(id=player_id).first()
        if player is None:
            return {
                "error": "player not found"
            }, 404

        game = Game.query.filter_by(id=player.game_id).first()
        # if game is None:
        #     return {
        #         "error": "game not found"
        #     }, 404

        # if game.started != True:
        #     return {
        #         "error": "game not started"
        #     }, 400

        # if player.alive is False:
        #     return {
        #         "error": "player is dead"
        #     }, 400

        # if game.questions[player.score]["correct"] == answer:
        #     player.score += 1
        # else:
        #     player.alive = False

        player.score += 1

        db.session.commit()
        return {
            "player_id": player.id,
            "score": player.score,
            "alive": player.alive
        }

api.add_resource(GameResource, "/game/<int:game_id>/<string:player_name>")
api.add_resource(PlayerResource, "/player/<int:game_id>/<int:player_id>/<int:answer>")

if __name__ == '__main__':
    with app.app_context():
        db.create_all()
    app.run(host='0.0.0.0', port=5000, debug=True)
