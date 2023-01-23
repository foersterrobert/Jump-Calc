from flask import Flask
from flask_restful import Api, Resource, reqparse, abort
from flask_sqlalchemy import SQLAlchemy

app = Flask(__name__)
api = Api(app)
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///database.db'
db = SQLAlchemy(app)

class PlayerModel(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    game = db.Column(db.Integer, nullable=False)
    x = db.Column(db.Integer, nullable=False)
    y = db.Column(db.Integer, nullable=False)
    z = db.Column(db.Integer, nullable=False)
    r = db.Column(db.Integer, nullable=False)
    animation = db.Column(db.Integer, nullable=False)
    round = db.Column(db.Integer, nullable=False)
    walls = db.Column(db.String, nullable=False)
    dead = db.Column(db.String, nullable=False)
    name = db.Column(db.String, nullable=False)

    def __repr__(self):
        return f"{self.id};{self.game};{self.x};{self.y};{self.z};{self.r};{self.animation};{self.round};{self.walls};{self.dead};{self.name}"

# db.create_all()

Player_put_args = reqparse.RequestParser()
Player_put_args.add_argument("x", type=int, help="x of the Player", required=True)
Player_put_args.add_argument("y", type=int, help="y of the Player", required=True)
Player_put_args.add_argument("z", type=int, help="z of the Player", required=True)
Player_put_args.add_argument("r", type=int, help="r of the Player", required=True)
Player_put_args.add_argument("animation", type=int, help="r of the Player", required=True)
Player_put_args.add_argument("round", type=int, help="r of the Player", required=True)
Player_put_args.add_argument("walls", type=str, help="r of the Player", required=True)
Player_put_args.add_argument("dead", type=str, help="r of the Player", required=True)
Player_put_args.add_argument("name", type=str, help="r of the Player", required=True)


Player_update_args = reqparse.RequestParser()
Player_update_args.add_argument("x", type=int, help="x of the Player")
Player_update_args.add_argument("y", type=int, help="y of the Player")
Player_update_args.add_argument("z", type=int, help="z of the Player")
Player_update_args.add_argument("r", type=int, help="r of the Player")
Player_update_args.add_argument("animation", type=int, help="r of the Player")
Player_update_args.add_argument("round", type=int, help="r of the Player")
Player_update_args.add_argument("walls", type=str, help="r of the Player")
Player_update_args.add_argument("dead", type=str, help="r of the Player")
Player_update_args.add_argument("name", type=str, help="r of the Player")


class Player(Resource):
    ### Create Player
    def put(self, game_id, own_id):
        args = Player_put_args.parse_args()
        own = PlayerModel.query.filter_by(id=own_id).first()
        if not own:
            Player = PlayerModel(id=own_id, game=game_id, x=args['x'], y=args['y'], z=args['z'], r=args['r'], animation=args['animation'], round=args['round'], walls=args['walls'], dead=args['dead'], name=args['name'])
            db.session.add(Player)
            db.session.commit()
        other = PlayerModel.query.filter(PlayerModel.game==game_id, PlayerModel.id!=own_id).all()
        othern = PlayerModel.query.filter(PlayerModel.game==game_id, PlayerModel.id!=own_id).count()
        return {"data": str(other), "n": othern}

    ### Move Own; return Other
    def post(self, game_id, own_id):
        args = Player_update_args.parse_args()
        own = PlayerModel.query.filter_by(id=own_id).first()
        if own:
            own.game = game_id
            if args['x']:
                own.x = args['x']
            if args['y']:
                own.y = args['y']
            if args['z']:
                own.z = args['z']
            if args['r']:
                own.r = args['r']
            if args['animation']:
                own.animation = args['animation']
            if args['round']:
                own.round = args['round']
            if args['walls']:
                own.walls = args['walls']
            if args['dead']:
                own.dead = args['dead']
            if args['name']:
                own.name = args['name']
            db.session.commit()
        if not own:
            abort(404, message='Player doesn"t exist, cannot update')
        other = PlayerModel.query.filter(PlayerModel.game==game_id, PlayerModel.id!=own_id).all()
        othern = PlayerModel.query.filter(PlayerModel.game==game_id, PlayerModel.id!=own_id).count()  
        return {"data": str(other), "n": othern}

    ### Delete Player
    def delete(self, game_id, own_id):
        pass

api.add_resource(Player, "/3d/<int:game_id>/<int:own_id>")

if __name__ == "__main__":
    app.run()