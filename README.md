# Rails-Avanzado
### Ruby en Rails avanzado

Antes de comenzar con la actividad primero ejecutaremos ```rails server``` para esto primero inicializamos las gemas con ```bundle install```. Vemos que al ejecutar por promiera vez en pantalla se ve lo siguiente.

![](https://github.com/Kinartb/Rails-Avanzado/blob/main/imagenes/actividad0.png)

Esto quiere decir que la tabla ```Moviegoer``` aun no ha sido creada por lo que mientras tanto cambiaremos en el codigo de ```app/controllers/application_controller.rb``` y cambiamos la palabras Moviegoer por Movie, posteriormente ejecutaremos el comando ```rails db:migrate``` y ejecutaremos nuevamente el comando ```rails server```.

![](https://github.com/Kinartb/Rails-Avanzado/blob/main/imagenes/actividad1.png)

Ahora nos aparece la tabla de manera correcta

Las validaciones de modelos, al igual que las migraciones, se expresan en un mini-DSL integrado en Ruby, como muestra en el siguiente código.  Escribe el código siguiente en el
código dado en ```app/models/movie.rb```

```ruby
class Movie < ActiveRecord::Base
    def self.all_ratings ; %w[G PG PG-13 R NC-17] ; end #  shortcut: array of strings
    validates :title, :presence => true
    validates :release_date, :presence => true
    validate :released_1930_or_later # uses custom validator below
    validates :rating, :inclusion => {:in => Movie.all_ratings},
        :unless => :grandfathered?
    def released_1930_or_later
        errors.add(:release_date, 'must be 1930 or later') if
        release_date && release_date < Date.parse('1 Jan 1930')
    end
    @@grandfathered_date = Date.parse('1 Nov 1968')
    def grandfathered?
        release_date && release_date < @@grandfathered_date
    end
end
```

y comprueba tus resultados en la consola, para esro usaremos la consola de comandos de ruby, ejecutaremos el comando ```rails console```.

```
m = Movie.new(:title => '', :rating => 'RG', :release_date => '1929-01-01')
# force validation checks to be performed:
m.valid?  # => false
m.errors[:title] # => ["can't be blank"]
m.errors[:rating] # => [] - validation skipped for grandfathered movies
m.errors[:release_date] # => ["must be 1930 or later"]
m.errors.full_messages # => ["Title can't be blank", "Release date must be 1930 or later"]
```
ahora veremos el output en consola

![](https://github.com/Kinartb/Rails-Avanzado/blob/main/imagenes/actividad2.png)

Se han realizado las pruebas correspondientes para lo solicitado

Explica el código siguiente :

```ruby 
class MoviesController < ApplicationController
  def new
    @movie = Movie.new
  end 
  def create
    if (@movie = Movie.create(movie_params))
      redirect_to movies_path, :notice => "#{@movie.title} created."
    else
      flash[:alert] = "Movie #{@movie.title} could not be created: " +
        @movie.errors.full_messages.join(",")
      render 'new'
    end
  end
  def edit
    @movie = Movie.find params[:id]
  end
  def update
    @movie = Movie.find params[:id]
    if (@movie.update_attributes(movie_params))
      redirect_to movie_path(@movie), :notice => "#{@movie.title} updated."
    else
      flash[:alert] = "#{@movie.title} could not be updated: " +
        @movie.errors.full_messages.join(",")
      render 'edit'
    end
  end
  def destroy
    @movie = Movie.find(params[:id])
    @movie.destroy
    redirect_to movies_path, :notice => "#{@movie.title} deleted."
  end
  private
  def movie_params
    params.require(:movie)
    params[:movie].permit(:title,:rating,:release_date)
  end
end
```

Este controlador maneja las operaciones CRUD (Crear, Leer, Actualizar, Eliminar) para las películas en la aplicación Rails, interactuando con la base de datos y gestionando las vistas asociadas.

Comprueba que el código siguiente ilustra cómo utilizar este mecanismo para “canonicalizar” (estandarizar el formato de) ciertos campos del modelo antes de guardar el modelo. 

```ruby
class Movie < ActiveRecord::Base
    before_save :capitalize_title
    def capitalize_title
        self.title = self.title.split(/\s+/).map(&:downcase).
        map(&:capitalize).join(' ')
    end
end
```

Comprueba en la consola : utilizaremos el comando ```rails console``` y escribimos lo siguiente

```
m = Movie.create!(:title => 'STAR  wars', :release_date => '27-5-1977', :rating => 'PG')
m.title  # => "Star Wars"
```

Veremos el output de lo que se percibe en consola.

![](https://github.com/Kinartb/Rails-Avanzado/blob/main/imagenes/actividad3.png)


#### SSO y autenticación a través de terceros 

Una manera de ser más DRY y productivo es evitar implementar funcionalidad que se puede reutilizar a partir de otros servicios. 
Un ejemplo muy actual de esto es la autenticación. 

Afortunadamente, añadir autenticación en las aplicaciones Rails a través de terceros es algo directo. Por supuesto, antes de que permitamos iniciar sesión a un usuario, ¡necesitamos poder representar usuarios! Así que antes de continuar, vamos a crear un modelo y una migración básicos siguiendo las instrucciones del código  siguiente:


a) Escribe este comando en una terminal para crear un modelo moviegoers y una migración, y ejecuta rake db:migrate para aplicar la migración. 

```
rails generate model Moviegoer name:string provider:string uid:string
```
Si se presenta algun problema se debe agregar lo siguiente ```--force``` para resolver el problema.

b) Luego edita el archivo `app/models/moviegoer.rb` generado para que coincida con este código. 

```ruby
# Edit app/models/moviegoer.rb to look like this:
class Moviegoer < ActiveRecord::Base
    def self.create_with_omniauth(auth)
        Moviegoer.create!(
        :provider => auth["provider"],
        :uid => auth["uid"],
        :name => auth["info"]["name"])
    end
end
```
Se puede autenticar al usuario a través de un tercero. Usar la excelente gema OmniAuth que proporciona una API uniforme para muchos proveedores de SSO diferentes. 
El código siguiente muestra los cambios necesarios en sus rutas, controladores y vistas para usar OmniAuth.  

Antes de iniciar debemos especificar el archivo GEMFILE y cambiarlo y agregarle estas dos gemas
```
gem 'omniauth'
gem 'omniauth-twitter'
```
Luego escribir ```bundle install``` para instalar las gemas.

Creamos un archivo ```config/initializers/omniauth.rb``` con la siguiente configuración. Reemplaza "API_KEY" y "API_SECRET" con las claves que obtuviste al registrar tu aplicación en Twitter.

```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :twitter, "API_KEY", "API_SECRET"
end
```

En el archivo ```config/routes.rb```, agrega las rutas necesarias para manejar la autenticación:

```
#routes.rb
get  'auth/:provider/callback' => 'sessions#create'
get  'auth/failure' => 'sessions#failure'
get  'auth/twitter', :as => 'login'
post 'logout' => 'sessions#destroy'
```

Por ultimo creamos un controlador de sesiones (sessions_controller.rb) con las acciones necesarias para manejar la autenticación:

```
class SessionsController < ApplicationController
  # login & logout actions should not require user to be logged in
  skip_before_filter :set_current_user  # check you version
  def create
    auth = request.env["omniauth.auth"]
    user =
      Moviegoer.where(provider: auth["provider"], uid: auth["uid"]) ||
      Moviegoer.create_with_omniauth(auth)
    session[:user_id] = user.id
    redirect_to movies_path
  end
  def destroy
    session.delete(:user_id)
    flash[:notice] = 'Logged out successfully.'
    redirect_to movies_path
  end
end
```
Ejecutamos ```rails server``` y veamos

![](https://github.com/Kinartb/Rails-Avanzado/blob/main/imagenes/actividad4.png)

Parece que debemos ejecutar el comando ```rails db:migrate RAILS_ENV=development``` para actualizar el conjunto. A continuacion vemos que todo se realiza con normalidad.

![](https://github.com/Kinartb/Rails-Avanzado/blob/main/imagenes/actividad3.1.png)


La mayoría de los proveedores de autenticación requieren que tu registre cualquier aplicación que utilizará su sitio para la autenticación, por lo que en este ejemplo necesitarás crear una cuenta de desarrollador de Twitter, que te asignará una clave API y un secreto API que especificarás en `config/initializers/ omniauth.rb` (codigo anterior, abajo).

**Pregunta:** Debes tener cuidado para evitar crear una vulnerabilidad de seguridad. ¿Qué sucede si un atacante malintencionado crea un envío de formulario que intenta modificar `params[:moviegoer][:uid]` o `params[:moviegoer][:provider]` (campos que solo deben modificarse mediante la lógica de autenticación) publicando campos de formulario ocultos denominados `params[moviegoer][uid]` y así sucesivamente?.

**Respuesta** Si un atacante malintencionado intenta manipular los campos params[:moviegoer][:uid] o params[:moviegoer][:provider] incluyendo campos ocultos en un formulario, podrían intentar realizar cambios no autorizados en la información crítica del usuario, como su identificador (uid) o proveedor (provider). Esto podría llevar a una suplantación de identidad o a la modificación indebida de información del usuario.

#### Asociaciones y claves foráneas 

Una asociación es una relación lógica entre dos tipos de entidades de una arquitectura software. 
Por ejemplo, podemos añadir a RottenPotatoes las clases Review (crítica) y Moviegoer (espectador o usuario) para permitir que los usuarios escriban críticas sobre sus películas favoritas; podríamos hacer esto añadiendo una asociación de uno a muchos (one-to-many) entre las críticas y las películas (cada crítica es acerca de una película) y entre críticas y usuarios (cada crítica está escrita por exactamente un usuario). 

Explica la siguientes líneas de SQL:

```
SELECT reviews.*
    FROM movies JOIN reviews ON movies.id=reviews.movie_id
    WHERE movies.id = 41;
```
**Respuesta** realizan una consulta que selecciona todas las columnas de la tabla reviews donde el id de la película (movie_id en la tabla reviews) es igual a 41. 

Aplica los cambios del código siguiente y arranca `rails console` y ejecutar correctamente los ejemplos del código. 

(a): Crea y aplica esta migración para crear la tabla Reviews. Las claves foraneas del nuevo modelo están relacionadas con las tablas movies y moviegoers existentes por convención sobre la configuración. 

```ruby
# Run 'rails generate migration create_reviews' and then
#   edit db/migrate/*_create_reviews.rb to look like this:
class CreateReviews < ActiveRecord::Migration
    def change
        create_table 'reviews' do |t|
        t.integer    'potatoes'
        t.text       'comments'
        t.references 'moviegoer'
        t.references 'movie'
        end
    end
end
```
b) Coloca este nuevo modelo de revisión en `app/models/review.rb`. 
```ruby
class Review < ActiveRecord::Base
    belongs_to :movie
    belongs_to :moviegoer
end
```

c) Coloca una copia de la siguiente línea en cualquier lugar dentro de la clase Movie Y dentro de la clase `Moviegoer` (idiomáticamente, debería ir justo después de 'class Movie' o 'class Moviegoer'), es decir realiza este cambio de una línea en cada uno de los archivos existentes `movie.rb` y `moviegoer.rb`.

```
has_many :reviews
```

#### Asociaciones indirectas

Volviendo a la figura siguiente, vemos asociaciones directas entre Moviegoers y Reviews, así como entre Movies y Reviews.

<img src="https://e.saasbook.info/assets/Chapter5/5.9-1ff7ee5268d1af8d2bc0cd61ac7a0f113c248deb1188de757f86b0e192d9c2b2.jpg" alt="drawing" width="500"/>

Comprueba que el código muestra cómo se usa la opción `:through` en `has_many` para representar una asociación indirecta. De la misma manera, puede añadir `has_many:moviegoers,:through=>:reviews` al modelo `Movie` y escribir `movie.moviegoers` para preguntar qué usuarios están asociados con (escribieron críticas de) una película dada. 

```
# Run 'rails generate migration create_reviews' and then
#   edit db/migrate/*_create_reviews.rb to look like this:
class CreateReviews < ActiveRecord::Migration
    def change
        create_table 'reviews' do |t|
        t.integer    'potatoes'
        t.text       'comments'
        t.references 'moviegoer'
        t.references 'movie'
        end
    end
end
```

¿Qué indica el siguiente código SQL ?

```
SELECT movies .*
    FROM movies JOIN reviews ON movies.id = reviews.movie_id
    JOIN moviegoers ON moviegoers.id = reviews.moviegoer_id
    WHERE moviegoers.id = 1;
```

**Respuesta** realiza una consulta que selecciona todas las columnas de la tabla movies donde hay una relación entre las tablas movies, reviews, y moviegoers, y donde el id del moviegoer es igual a 1. 



* Existen opciones adicionales en los métodos de asociaciones que controlan lo que pasa a los objetos que son “tenidos” cuando el objeto “poseedor” se destruye. Por ejemplo, `has_many :reviews,:dependent=>:destroy` especifica que las críticas que pertenezcan a una determina película se deben borrar de la base de datos si se borra esa película.
