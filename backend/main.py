import random
from flask import Flask
from flask_restful import Api, Resource
from flask_sqlalchemy import SQLAlchemy

app = Flask(__name__)
api = Api(app)
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///database.db'
db = SQLAlchemy(app)

def generate_questions():
    questions = [
        ["What is the capital of France?", "Paris", "London", "Berlin", "Madrid", 0],
        ["What is the capital of Germany?", "Berlin", "London", "Paris", "Madrid", 0],
        ["What is the capital of Spain?", "Madrid", "London", "Berlin", "Paris", 0],
        ["What is the capital of England?", "London", "Madrid", "Berlin", "Paris", 0],
        ["What is the capital of Italy?", "Rome", "Madrid", "Berlin", "Paris", 0],
        ["What is the capital of Portugal?", "Lisbon", "Madrid", "Berlin", "Paris", 0],
        ["What is the capital of Poland?", "Warsaw", "Madrid", "Berlin", "Paris", 0],
        ["What is the capital of Sweden?", "Stockholm", "Madrid", "Berlin", "Paris", 0],
        ["What is the capital of Norway?", "Oslo", "Madrid", "Berlin", "Paris", 0],
    ]
    return questions

class Game(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    started = db.Column(db.Boolean, default=False)
    public = db.Column(db.Boolean, default=False)
    questions = db.Column(db.JSON, default=[])
    
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
        return f"Player(id={self.id}, name={self.name}, score={self.score}), alive={self.alive})"

class GameResource(Resource):
    ### Create Game
    def post(self, player_name, public):
        while True:
            game_id = random.randint(1000, 9999)
            if Game.query.filter_by(id=game_id).first() is None:
                break
        public = True if public == "true" else False
        game = Game(id=game_id, public=public, questions=generate_questions())

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
            "player_id": player.id,
            "questions": game.questions
        }
    
    ### Join Game
    def put(self, game_id, player_name):
        game = Game.query.filter_by(id=game_id).first()
        if game is None:
            return {
                "error": "game not found"
            }, 404

        if game.started:
            return {
                "error": "game already started"
            }, 400

        while True:
            player_id = random.randint(1000, 9999)
            if Player.query.filter_by(id=player_id).first() is None:
                break

        player = Player(id=player_id, name=player_name, game_id=game_id)

        db.session.add(player)
        db.session.commit()
        return {
            "game_id": game.id,
            "player_id": player.id,
            "questions": game.questions
        }
    
    ### Get Game
    def get(self, game_id):
        game = Game.query.filter_by(id=game_id).first()
        if game is None:
            return {
                "error": "game not found"
            }, 404

        players = Player.query.filter_by(game_id=game_id).all()
        players = " | ".join([f"{player.name}, {player.score}, {player.alive}" for player in players])
        
        return {
            "game_id": game.id,
            "started": game.started,
            "players": players
        }
    
    ### Get all public games
    def patch(self):
        games = Game.query.filter_by(public=True).all()
        games_str = " | ".join([f"{game.id}" for game in games])
        if games_str == "":
            games_str = "No public games"
        return {
            "games": games_str
        }

class PlayerResource(Resource):
    ### Answer Question
    def put(self, player_id, answer):
        player = Player.query.filter_by(id=player_id).first()
        if player is None:
            return {
                "error": "player not found"
            }, 404

        game = Game.query.filter_by(id=player.game_id).first()
        if game is None:
            return {
                "error": "game not found"
            }, 404

        if game.started != True:
            return {
                "error": "game not started"
            }, 400

        if player.alive is False:
            return {
                "error": "player is dead"
            }, 400

        if game.questions[player.score][5] == answer:
            player.score += 1
        else:
            player.alive = False

        if player.score == len(game.questions):
            player.score = 0

        db.session.commit()
        return {
            "player_id": player.id,
            "score": player.score,
            "alive": player.alive
        }
    
    ### Start Game
    def patch(self, game_id):
        game = Game.query.filter_by(id=game_id).first()
        if game is None:
            return {
                "error": "game not found"
            }, 404
        if game.started:
            return {
                "error": "game already started"
            }, 400
        game.started = True
        db.session.commit()
        return {
            "game_id": game.id
        }

api.add_resource(GameResource, "/game/<string:player_name>/<public>", "/game/<int:game_id>/<string:player_name>", "/game/<int:game_id>", "/game")
api.add_resource(PlayerResource, "/player/<int:game_id>", "/player/<int:player_id>/<int:answer>")
with app.app_context():
    db.create_all()

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
