//Under GNU AGPL v3, see LICENCE
package beartek.matrix_im.client;

import com.akifox.asynchttp.AsyncHttp;
import beartek.matrix_im.client.Conection;
import beartek.matrix_im.client.auths.*;
import beartek.matrix_im.client.types.*;
import beartek.matrix_im.client.types.replys.*;
import beartek.matrix_im.client.types.enums.*;

class Test_client extends mohxa.Mohxa {
  var conection : Conection;
  var reply_recived : Bool = false;
  var error : String = '';

  var auth_data : {user: String, pass: String} = {user: 'test', pass: 'test'};
  var login_data : {acces_token: String, device_id: String, home_server: String, user_id: String};
  var filter : String = '';


  public function new( server : String ) : Void {
    super();
    this.describe('Crear conexion', function() : Void {
      this.conection = new Conection(server);
      this.conection.on_error = function( e : Dynamic ) : Void {
        this.error = Std.string(e);
      }
    });
    this.test_create_and_destroy();
    this.test_login();

    this.test_server_adm();
    this.test_account();
    this.test_filters();
    this.test_sync();

    this.test_logout();
  }

  public function test_create_and_destroy() : Void {
    this.describe('Probando a crear cuenta y borrarla', function() : Void {
      this.it('Creandola', function() : Void {
        conection.account.register( 'Tester_haxe_matrix_' + this.auth_data.user, this.auth_data.pass, false,
        function( data : Login_data ) : Void {
          this.log(Std.string(data));
        }, function( type : Auths, auth : Dynamic ) : Void {
            switch type {
            case Auths.Password:
              var a : M_login_password = auth;
              a.login_with_user('Tester_haxe_matrix_' + this.auth_data.user, this.auth_data.pass);
            case Auths.Email:
              throw 'Identity server API not implemented';
            case Auths.Token:
              throw 'Not implemented';
            case Auths.Dummy:
              var a : M_login_dummy = auth;
              a.make_pet();
            case Auths.Oauth2:
              var a : M_login_oauth2 = auth;
              this.log('Go to: ' + a.get_uri() );
              this.log('Login, and press any key to continue');

              Sys.getChar(false);

              a.make_pet();
            case _:
              var a : Unknow_auth = auth;
              this.log('Go to: ' + a.get_fallback(conection.server_url));
              this.log('Login, and press any key to continue');

              Sys.getChar(false);

              a.make_pet();
            }
          });
      });
      this.it('Borrandola', function() : Void {
        conection.account.deactivate(function( n : Null<Dynamic> ) : Void {
          this.log('Borrada');
        }, function( type : Auths, auth : Dynamic ) : Void {
            switch type {
            case Auths.Password:
              var a : M_login_password = auth;
              a.login_with_user('Tester_haxe_matrix_' + this.auth_data.user, this.auth_data.pass);
            case Auths.Email:
              throw 'Identity server API not implemented';
            case Auths.Token:
              throw 'Not implemented';
            case Auths.Dummy:
              var a : M_login_dummy = auth;
              a.make_pet();
            case Auths.Oauth2:
              var a : M_login_oauth2 = auth;
              this.log('Go to: ' + a.get_uri() );
              this.log('Login, and press any key to continue');

              Sys.getChar(false);

              a.make_pet();
            case _:
              var a : Unknow_auth = auth;
              this.log('Go to: ' + a.get_fallback(conection.server_url));
              this.log('Login, and press any key to continue');

              Sys.getChar(false);

              a.make_pet();
            }
          });
      });
    });
  }

  public function test_sync() : Void {
    this.describe('Probando sincronizacion', function() : Void {
      this.it('Registrando handlers', function() : Void {
        conection.sync.add_room_handler(function( rooms : Map<String,Joined_room> ) : Void {
          this.log('This account groups: ');
          for( room in rooms.keys() ) {
            this.log('In ' + room);
            this.log('Has ' + rooms[room].unread_notifications.notification_count + ' Unreaded notification');
            this.log('Other data: ' + rooms[room]);
          }
        });

        conection.sync.add_presence_handler(function( presence : Array<Event<Dynamic>> ) : Void {
          this.log('Current presence events: ' + presence);
        });

        conection.sync.add_account_data_handler(function( account : Array<Event<Dynamic>> ) : Void {
          this.log('Account data: ' + account);
        });
      });

      this.it('Sincronizando', function() : Void {
        conection.sync.sync(this.filter);
      });
    });
  }

  public function test_filters() : Void {
    var room_filter : Room_filter = {
      state: {limit: 5, types: ['m.room.*'],not_rooms: ['!726s6s6q:example.com'],contains_url : false},
      timeline: {limit: 10, contains_url : false},
      ephemeral: [{types: ['m.typing'], limit: 10, contains_url : false}],
      account_data: {limit: 10, contains_url : false},
      include_leave: false};
    this.describe('Probando filtros', function() : Void {
      this.it('Creando filtro', function() : Void {
        conection.filters.add_filter(conection.session.user, {limit: 5, senders: [conection.session.user.toString(), '@this:atest.is']}, {limit: 5, senders: [conection.session.user, '@this:atest.is']}, room_filter, function( id : String ) : Void {
          filter = id;
          this.log('Filter id:' + filter);
        });
      });
      this.it('obteniendo filtro', function() : Void {
        conection.filters.get_filter(conection.session.user, filter, function( parts : Null<Array<String>>, presence: Filter, account : Filter, room: Room_filter ) : Void {
          this.equal(presence.limit == 5, true);
          this.equal(account.limit == 5, true);
          this.equal(Std.string(room) == Std.string(room_filter), true);
          this.equal(parts, null);
        });
      });
    });
  }

  public function test_account() : Void {
    this.describe('Probando Cuenta', function() : Void {
      this.it('Obteniendo informacion de contacto', function() : Void {
        conection.account.get_3pid(function( info : Array<Threepid> ) : Void {
          this.log(info);
        });
      });
      this.it('Quien soy', function() : Void {
        conection.account.whoami(function( user : User ) : Void {
          this.equal(user.equal(conection.session.user), true);
        });
      });
      this.it('Cambiando pass a la misma pass', function() : Void {
        conection.account.change_password(this.auth_data.pass,
          function( n : Null<Dynamic> ) : Void {
            this.log('changed. ' + n);
        }, function( type : Auths, auth : Dynamic ) : Void {
            switch type {
            case Auths.Password:
              var a : M_login_password = auth;
              a.login_with_user(this.auth_data.user, this.auth_data.pass);
            case Auths.Email:
              throw 'Identity server API not implemented';
            case Auths.Token:
              throw 'Not implemented';
            case Auths.Dummy:
              var a : M_login_dummy = auth;
              a.make_pet();
            case Auths.Oauth2:
              var a : M_login_oauth2 = auth;
              this.log('Go to: ' + a.get_uri() );
              this.log('Login, and press any key to continue');

              Sys.getChar(false);

              a.make_pet();
            case _:
              var a : Unknow_auth = auth;
              this.log('Go to: ' + a.get_fallback(conection.server_url));
              this.log('Login, and press any key to continue');

              Sys.getChar(false);

              a.make_pet();
            }
        });
      });

      //TODO: test para validate email, y anadir 3pid
    });
  }

  public function test_server_adm() : Void {
    this.describe('Probando Administracion del servidor', function() : Void {
      this.it('Obteniendo versiones del protocolo', function() : Void {
        this.log(conection.server.versions);
        this.equal(conection.server.versions.length > 0, true);
      });
      this.it('Haciendo WHOIS (falla si el usuario no es admin en el servidor)', function() : Void {
        conection.server.whois(conection.session.user, function( response : Dynamic ) : Void {
          this.log(Std.string(response));
        });
      });
    });
  }

  public function test_login() : Void {
    this.describe('Probando a loguearse', function() : Void {
      if( Sys.args()[1] != null && Sys.args()[2] != null ) {
        this.log('Usando usuario y contrasena pasados por cli.');
        this.auth_data = {user: Sys.args()[1], pass: Sys.args()[2]};
      } else {
        this.log('Usando usuario y contrasena test/test.');
      }
      this.it('logueandose', function() : Void {
        conection.session.login_with_pass(auth_data.user, auth_data.pass, 'Tester', function( respose : Dynamic ) : Void {
          this.reply_recived = true;
          if( Reflect.field(respose, 'access_token') != null ) {
            this.login_data = respose;
            this.log('logueado correctamente, datos : ' + this.login_data);
          } else {
            throw 'respuesta invalida: ' + respose;
          }
        });
      });
    });
  }

  public function test_logout() : Void {
    this.describe('Probando a desloguearse', function() : Void {
      this.it('Deslogueandose', function() : Void {
        conection.session.logout(function() : Void {
          this.log('Deslogueado');
        });
      });
    });
  }
}
