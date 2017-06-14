The JavaScript world is currently in great turbulence. A new framework pops up daily, developers are confused about which tools they’re supposed to pick up, and building user interfaces is experiencing dramatic changes. On top of that, us Rails developers know that .erb views are going out of fashion, too--and being replaced by much more sophisticated JavaScript-based frameworks. Given all this, it can be difficult to pick up something to commit to.
...
El mundo de JavaScript está actualmente en gran turbulencia. Un nuevo marco aparece a diario, los desarrolladores están confundidos acerca de qué herramientas se supone que recoger, y la construcción de interfaces de usuario está experimentando cambios dramáticos. Además, los desarrolladores de Rails saben que las vistas .erb también están saliendo de moda, y están siendo reemplazadas por frameworks mucho más sofisticados basados ​​en JavaScript. Teniendo en cuenta todo esto, puede ser difícil de recoger algo para comprometerse a.

Fortunately, Facebook’s [React](https://facebook.github.io/react/docs/reconciliation.html) provides a ray of hope by promising a novel approach to building user interfaces. Even better, Rails can seamlessly integrate with it, and it’s easy to set up a Rails API application and to build its view layer with React. So, let’s take a look at how to build a simple Rails API that accommodates create, read, update and delete functionality for a single model with React. 
...
Afortunadamente, Facebook [React] (https://facebook.github.io/react/docs/reconciliation.html) proporciona un rayo de esperanza al prometer un nuevo enfoque para la construcción de interfaces de usuario. Incluso mejor, Rails puede integrarse perfectamente con él, y es fácil configurar una aplicación de Rails API y construir su capa de vista con React. Por lo tanto, echemos un vistazo a cómo construir una API de Rails simple que permite crear, leer, actualizar y eliminar la funcionalidad de un solo modelo con React.
 
Setting up a basic Rails API
--

#### Setting up the model

We’re going to employ a different approach to the application’s architecture. We’ll use Rails only to render data in JSON, while React will handle the views and the displaying of data. This will separate the Rails application from the view layer.
...
Vamos a emplear un enfoque diferente a la arquitectura de la aplicación. Usaremos Rails sólo para procesar datos en JSON, mientras que React manejará las vistas y la visualización de datos. Esto separará la aplicación Rails de la capa de vista. 

First, let’s initialize an empty rails application:

|||-------------------------------------||||||bash
$ rails new item_cart
|||-------------------------------------||||||

Now, let’s create the model for which we’ll build a CRUD interface:
...
Ahora, vamos a crear el modelo para el cual construiremos una interfaz CRUD:

|||-------------------------------------||||||bash
$ rails g model Item name:string description:text
|||-------------------------------------||||||

This will create a model with a name and description attributes, and a database migration for it.  We just need to add the model to the database schema.
...
Esto creará un modelo con un nombre y atributos de descripción, y una migración de base de datos para él. Sólo necesitamos agregar el modelo al esquema de la base de datos.
|||-------------------------------------||||||bash
$ rake db:migrate
|||-------------------------------------||||||

#### Adding some seed data

Now it’s time to populate our database with some sample data! We’ll need it to make sure what we’re going to implement works properly. The following script will populate our database with 10 arbitrary items.
...
Ahora es el momento de llenar nuestra base de datos con algunos datos de muestra! Lo necesitaremos para asegurarnos de que lo que vamos a implementar funcione correctamente. El siguiente script llenará nuestra base de datos con 10 elementos arbitrarios.

|||-------------------------------------||||||ruby
#db/seeds.rb

10.times { Item.create!(name: "Item", description: "I am a description.") }

|||-------------------------------------||||||

|||-------------------------------------||||||bash
$ rake db:seed
|||-------------------------------------||||||

#### Setting up the controllers

Time to move to the controllers. First, we’ll install the `responders` gem, which will let us apply a `respond_to` rule to all the actions in our controllers, making the code DRY-er. 
Put the gem in your gemfile and bundle it:
...
#### Configuración de los controladores

Es hora de pasar a los controladores. En primer lugar, instalaremos la joya de `responders`, que nos permitirá aplicar una regla` respond_to` a todas las acciones de nuestros controladores, haciendo que el código DRY-er.
Ponga la gema en su gemfile y bundle it:

|||-------------------------------------||||||ruby
gem 'responders'
|||-------------------------------------||||||

|||-------------------------------------||||||bash
$ bundle
|||-------------------------------------||||||

Second, we’ll make a small adjustment to the application controller. Except throwing an exception, we’ll make the controller throw a `null session` because we’re going to request json, which is different to the html (which is requested by default).
...
En segundo lugar, haremos un pequeño ajuste al controlador de la aplicación. Excepto lanzar una excepción, haremos que el controlador lance una `sesión nula` porque vamos a solicitar json, que es diferente al html (que se solicita de forma predeterminada).


|||-------------------------------------||||||ruby
#application_controller.rb


class ApplicationController < ActionController::Base
  protect_from_forgery with: :null_session
end

|||-------------------------------------||||||


Because this is an API-based application, we’ll structure the controllers using namespaces. By convention, we have to put the controllers for the different namespaces in folders corresponding to their namespace. For example, all controllers belonging to the `api` namespace must be put in a folder named ‘api’.  In the ‘controllers’ folder (in our application), we’ll create a folder named `api` and, in it, another folder named `v1`:
...
Debido a que se trata de una aplicación basada en API, estructuraremos los controladores utilizando espacios de nombres. Por convención, tenemos que poner los controladores para los diferentes espacios de nombres en las carpetas correspondientes a su espacio de nombres. Por ejemplo, todos los controladores pertenecientes al espacio de nombres `api` deben colocarse en una carpeta llamada 'api'. En la carpeta 'controllers' (en nuestra aplicación), crearemos una carpeta llamada `api` y, en ella, otra carpeta llamada` v1`:

|||-------------------------------------||||||bash
app/controllers/api/v1
|||-------------------------------------||||||

In the `app/controllers/api/v1` directory, we’ll create two controllers. The base_controller will have global rules that apply to all of our API-based controllers.
...
En el directorio `app / controllers / api / v1`, crearemos dos controladores. El base_controller tendrá reglas globales que se aplican a todos nuestros controladores basados ​​en API.


|||-------------------------------------||||||ruby
#base_controller.rb

class Api::V1::BaseController < ApplicationController
  respond_to :json
end

|||-------------------------------------||||||

The respond_to method ensures that all actions from the controllers, which inherit from the base controller, will respond with JSON. This is the standard approach for building JSON-based APIs. After we’re done with the base controller, we can create a controller for our Item model. We’ll make the controller inherit from the base controller and put the standard index, create update and destroy actions.
...
El método responder_a asegura que todas las acciones de los controladores, que heredan del controlador base, responderán con JSON. Este es el método estándar para crear API basadas en JSON. Después de terminar con el controlador base, podemos crear un controlador para nuestro modelo de artículo. Haremos que el controlador hereda de la base de control y poner el índice estándar, crear actualizar y destruir acciones.


|||-------------------------------------||||||ruby
#items_controller.rb

class Api::V1::ItemsController < Api::V1::BaseController
  def index
    respond_with Item.all
  end

  def create
    respond_with :api, :v1, Item.create(item_params)
  end

  def destroy
    respond_with Item.destroy(params[:id])
  end

  def update
    item = Item.find(params["id"])
    item.update_attributes(item_params)
    respond_with item, json: item
  end

  private

  def item_params
    params.require(:item).permit(:id, :name, :description)
  end
end
xxxxxxxxxxx
|||-------------------------------------||||||

The respond_with method is part of the `responders` gem and will return a JSON object with the results of each action in the controller.

The routing for the controller has to consider the fact that it’s within two namespaces; API and V1. We’ll do this using the namespace method.

#### Routing the controllers
...
El método respond_with forma parte de la joya `responders` y devolverá un objeto JSON con los resultados de cada acción en el controlador.

El enrutamiento para el controlador tiene que considerar el hecho de que está dentro de dos namespaces; API y V1. Lo haremos utilizando el método de espacio de nombres.

#### Enrutamiento de los controladores


|||-------------------------------------||||||ruby
#app/config/routes.rb

Rails.application.routes.draw do
    namespace :api do
      namespace :v1 do
        resources :items, only: [:index, :create, :destroy, :update]
      end
    end
  end


|||-------------------------------------||||||
To see if everything works, go to:

|||-------------------------------------||||||bash
http://localhost:3000/api/v1/items.json
|||-------------------------------------||||||

If you see an array for JSON objects, you’re good to go!

We’re done with the API, but where will we render React? Let’s build a static view where the application will lead us. First, we’ll have to create a controller that’s solely responsible for rendering the static view.
...
Si ve una matriz para objetos JSON, ¡es bueno ir!

Ya hemos terminado con la API, pero ¿dónde haremos React? Vamos a construir una vista estática donde la aplicación nos llevará. En primer lugar, tendremos que crear un controlador que sea el único responsable de representar la vista estática.



|||-------------------------------------||||||ruby
#app/controllers/site_controller.rb


class SiteController < ApplicationController
  def index
  end
end

|||-------------------------------------||||||


|||-------------------------------------||||||ruby

#app/config/routes.rb
Rails.application.routes.draw do
  root to: 'site#index'
|||-------------------------------------||||||


#### Adding React to Rails

Add `react-rails` to the Gemfile.

|||-------------------------------------||||||ruby
gem 'react-rails'
|||-------------------------------------||||||

|||-------------------------------------||||||bash
$ bundle
$ rails g react:install
|||-------------------------------------||||||

The react:install generator will automatically include the react JavaScript library in your asset pipeline
...
El generador reaccionar: instalar incluirá automáticamente la biblioteca de JavaScript de reacciones en la canalización de activos


|||-------------------------------------||||||bash
$ rails g react:install
        create app/assets/javascripts/components
        create app/assets/javascripts/components/.gitkeep
        insert app/assets/javascripts/application.js
        insert app/assets/javascripts/application.js
        insert app/assets/javascripts/application.js
        create app/assets/javascripts/components.js
|||-------------------------------------||||||

Like JQuery and the rest of the JavaScript libraries, react and react_ujs are included in the asset pipeline. The components folder in the `assets/javascripts` directory is where we’ll store our components. Speaking of components, these are the building blocks of the React framework. They’re used to separate the different sections of a user interface and are structured in a parent-child relationship, similar to the way nested AngularJS controllers work.
...
Al igual que JQuery y el resto de las bibliotecas de JavaScript, react y react_ujs se incluyen en la canalización de activos. La carpeta de componentes del directorio `assets / javascripts` es donde almacenaremos nuestros componentes. Hablando de componentes, éstos son los pilares del marco de React. Se utilizan para separar las diferentes secciones de una interfaz de usuario y se estructuran en una relación padre-hijo, similar a la forma en que los controladores AngularJS anidados funcionan.

For example, let’s say you want to build a simple layout with a body, header and a list of items. Here’s how its hierarchy would be structured:
...
Por ejemplo, supongamos que desea crear un diseño sencillo con un cuerpo, encabezado y una lista de elementos. Así se estructurará su jerarquía:

![](http://i.imgur.com/jzjTEXb.png)

`< Main/ >` renders `< Header/ >` and `< Body/ >` and sends information down the hierarchy. `< Header / >` may receive information about the current user and the menu and `< Body / >` can receive an array of items. The `< items / >` component will take the information and create a list of `< item / >` components which will contain data about every single object. The `< Attributes / >` component will contain information about the items and `< Actions / >` will contain a delete and edit button.
...
`<Main />` renderiza `<Header />` y `<Body />` y envía información por la jerarquía. `<Header />` puede recibir información sobre el usuario actual y el menú y `<Body />` puede recibir una matriz de elementos. El componente `<items />` tomará la información y creará una lista de componentes `<item />` que contendrán datos sobre cada objeto. El componente `<Attributes />` contendrá información sobre los elementos y `<Actions />` contendrá un botón delete y edit.

To make Rails render React components, we need to add the react_component view helper to our root route.
...
Para que Rails pueda procesar los componentes de React, debemos añadir el ayudante de vista de react_component a nuestra ruta raíz.



|||-------------------------------------||||||ruby
#app/views/site/index.html.erb

<%= react_component 'Main' %>
|||-------------------------------------||||||

The `react_component` is part of react-rails. In this case, it’s used to put the component named `Main` from the components folder in the assets directory into the view.
...
El `react_component` es parte de react-rails. En este caso, se utiliza para poner en la vista el componente denominado `Main` desde la carpeta components del directorio assets.

#### The first component

The first thing we need to do is to set-up a jsx file in our components folder.
...
Lo primero que debemos hacer es configurar un archivo jsx en nuestra carpeta de componentes.



|||-------------------------------------||||||javascript
// app/assets/javascripts/components/_main.js.jsx

var Main = React.createClass({
    render() {
        return (
            <div>
                <h1>Hello, World!</h1>
            </div>
        )
    }
});

|||-------------------------------------||||||

The `js.jsx` in React components works the same way as `html.erb` works for Rails; it’s an extension used to recognize the view files of the framework. This component has only one method; `render()`.  In this case, it’s used to return static html to the page. The `render()` method also triggers `render()` to all child components of the parent component, eventually printing all the components on the page. Each React component can only return one element, so all jsx elements in the return statement need to be in one wrapper div.
...
El `js.jsx` en los componentes React funciona de la misma manera que funciona` html.erb` para Rails; Es una extensión utilizada para reconocer los archivos de vista del marco. Este componente tiene sólo un método; `Render ()`. En este caso, se utiliza para devolver html estático a la página. El método `render ()` también activa `render ()` a todos los componentes secundarios del componente principal, imprimiendo finalmente todos los componentes de la página. Cada componente React sólo puede devolver un elemento, por lo que todos los elementos jsx en la instrucción return deben estar en una div div.

The `<Main />` component has two child components; `<Header />` and `<Body />`. Let’s start with the `<Header />` first.
...
El componente `<Main />` tiene dos componentes secundarios; `<Header />` y `<Body />`. Empecemos con el `<Header />` primero.


|||-------------------------------------||||||javascript

// app/assets/javascripts/components/_header.js.jsx

var Header = React.createClass({
    render() {
        return (
            <div>
                <h1>Hello, World!</h1>
            </div>
        )
    }
});
|||-------------------------------------||||||



And change our `<Main />` component so that it will render `<Header />` in its render function.
...
Y cambie nuestro componente `<Main />` para que muestre `<Header />` en su función render.


|||-------------------------------------||||||javascript

// app/assets/javascripts/components/_main.js.jsx

var Main = React.createClass({
    render() {
        return (
            <div>
                <Header />
            </div>
        )
    }
});

|||-------------------------------------||||||

Great! We just nested two components together.
...
¡Estupendo! Simplemente anidamos dos componentes juntos.



Rendering all the items
...
Representación de todos los elementos
--

As previously mentioned. All the items will be listed in the `<Body />` component. The `<Body />` component will also contain a form for inserting new items. Here’s the list of files that need to be created:
...
Como se menciono antes. Todos los elementos aparecerán en el componente `<Body />`. El componente `<Body />` también contendrá un formulario para insertar nuevos elementos. Esta es la lista de archivos que se deben crear:

|||-------------------------------------||||||bash
app/assets/javascripts/components/_body.js.jsx
app/assets/javascripts/components/_all_items.js.jsx
app/assets/javascripts/components/_new_items.js.jsx
|||-------------------------------------||||||

First, let’s start with listing all the items. Listing them will include making a request to the server to fetch all the items into our component using an AJAX request. We need to do it when the component gets rendered into the DOM. React has several built-in methods that handle different events during a component’s lifespan. There are methods that execute before and after component mounts into the DOM or before and after it dismounts from the DOM. In this case, we need a method that will handle the AJAX request when the component mounts.
...
En primer lugar, vamos a empezar con la lista de todos los elementos. El listado de ellos incluirá hacer una petición al servidor para que traiga todos los elementos a nuestro componente usando una solicitud de AJAX. Tenemos que hacerlo cuando el componente se procesa en el DOM. React tiene varios métodos integrados que manejan diferentes eventos durante la vida útil de un componente. Existen métodos que se ejecutan antes y después de que el componente se monta en el DOM o antes y después de que se desmonte del DOM. En este caso, necesitamos un método que maneje la solicitud AJAX cuando el componente se monta.


We’ll use `componentDidMount()`, which is called right after the component is mounted. You can find out about other component methods and how to use them in [React’s documentation](https://facebook.github.io/react/docs/component-specs.html).
...
Usaremos `componentDidMount ()`, que se llama justo después de montar el componente. Puede encontrar otros métodos de componentes y cómo usarlos en la documentación de [React] (https://facebook.github.io/react/docs/component-specs.html).



|||-------------------------------------||||||javascript
// app/assets/javascripts/components/_all_items.js.jsx

var AllItems = React.createClass({
    componentDidMount() {
        console.log('Component mounted');
    },

    render() {
        return (
            <div>
                <h1>All items component</h1>
            </div>
        )
    }
});


|||-------------------------------------||||||

Here’s how you implement the `componentDidMount()` method. Note how the methods are separated:  If we take a closer look at the `React.createClass` function, they’re defined as object properties, and they should be separated by commas. Don’t fret if you don’t see the `console.log()` message in your application - we still haven’t included it in a parent component and it won’t mount into the DOM!
...
Así es como implementa el método `componentDidMount ()`. Observe cómo se separan los métodos: Si examinamos de cerca la función `React.createClass`, se definen como propiedades del objeto y se deben separar por comas. No se preocupe si no ve el mensaje `console.log ()` en su aplicación - todavía no lo hemos incluido en un componente padre y no se montará en el DOM!


Before we fetch information from the server, we need to know how data is stored in the component. When the component is mounted, its data has to be initialized. This is done by the `getInitialState()` method. 
...
Antes de obtener información del servidor, necesitamos saber cómo se almacenan los datos en el componente. Cuando el componente está montado, sus datos tienen que ser inicializados. Esto se hace mediante el método `getInitialState ()`.


|||-------------------------------------||||||javascript
// app/assets/javascripts/components/_all_items.js.jsx

var AllItems = React.createClass({
    getInitialState() {
        return { items: [] }
    },

|||-------------------------------------||||||

Now, we need to get the data from the server and assign it to the items object. Here’s how we do it:
...
Ahora, necesitamos obtener los datos del servidor y asignarlos al objeto items. Así es como lo hacemos:

|||-------------------------------------||||||javascript
// app/assets/javascripts/components/_all_items.js.jsx

getInitialState() {
        return { items: [] }
},

componentDidMount() {
    $.getJSON('/api/v1/items.json', (response) => { this.setState({ items: response }) });
},

|||-------------------------------------||||||

We use the `getJSON` method with the URL of the `items.json` as an argument, and we use the `setState` function of the component to put the response into the items object.
...
Utilizamos el método `getJSON` con la URL de` items.json` como argumento, y usamos la función `setState` del componente para colocar la respuesta en el objeto items.

Okay, we’ve got the items, but how do we render them? We’re going to iterate through them in our `render()` method.
...
Bien, tenemos los artículos, pero ¿cómo los hacemos? Vamos a iterar a través de ellos en nuestro método `render ()`.


|||-------------------------------------||||||javascript
// app/assets/javascripts/components/_all_items.js.jsx

//getInitialState and componentDidMount

render() {
    var items= this.state.items.map((item) => {
        return (
            <div>
                <h3>{item.name}</h3>
                <p>{item.description}</p>
            </div>
        )
    });

    return(
        <div>
            {items}
        </div>
    )
}

|||-------------------------------------||||||

The map method is similar to the each method in the `.erb` templates. It iterates through the array of items and displays the items’ attributes using bracket notation. The brackets are equivalent to Rails’ `<%= =>` tags. They’re used to inject the item attributes into the html, making it dynamic. It eventually returns the items variable, which now is a DOM element with item attributes wrapped in html elements.
...
El método de mapa es similar a cada método en las plantillas `.erb`. It itera a través de la matriz de elementos y muestra los atributos de los elementos utilizando la notación de paréntesis. Los corchetes son equivalentes a las etiquetas `` <% = => `de Rails. Se utilizan para inyectar los atributos del elemento en el html, haciéndolo dinámico. Eventualmente devuelve la variable items, que ahora es un elemento DOM con atributos de elemento envueltos en elementos html.

But hold on--we’re not done just yet! When we iterate through items in React, there must be a way to identify each item into the component’s DOM. For that, we’ll use a unique attribute of each item, also known as `key`. To add a key to the item, we need to use the key attribute in the div that wraps it, like this:
...
Pero aguanta, ¡todavía no hemos terminado! Cuando iteramos a través de elementos en React, debe haber una manera de identificar cada elemento en el DOM del componente. Para ello, utilizaremos un atributo único de cada elemento, también conocido como `key`. Para agregar una clave al elemento, necesitamos usar el atributo clave en la div que lo envuelve, así:

|||-------------------------------------||||||javascript
// app/assets/javascripts/components/_all_items.js.jsx

    var items= this.state.items.map((item) => {
        return (
            <div key={item.id}>
                <h3>{item.name}</h3>
                <p>{item.description}</p>
            </div>
        )
    });

    return(
        <div>
            {items}
        </div>
    )
}

|||-------------------------------------||||||


Did you notice the key attribute in the div element that’s used in the iterator method in the items variable? Keys play an important part in lists of similar elements, as they provide a way for them to be identified and interacted with. You can learn more about keys in the [React’s documentation](https://facebook.github.io/react/docs/reconciliation.html).
...
¿Notó el atributo clave en el elemento div que se utiliza en el método iterador en la variable items? Las llaves juegan un papel importante en listas de elementos similares, ya que proporcionan una manera para que se identifiquen e interactúen con ellos. Puede obtener más información sobre las claves en la documentación de [React] (https://facebook.github.io/react/docs/reconciliation.html).

Let’s test if everything is working. First, `<Body />` , the parent component of `<AllItems />` and `<NewItem />` must be put into the `<Main />` component.
...
Vamos a probar si todo está funcionando. Primero, `<Body />`, el componente padre de `<AllItems />` y `<NewItem />` deben ser colocados en el componente `<Main />`.


|||-------------------------------------||||||javascript
// app/assets/javascripts/components/_main.js.jsx
var Main = React.createClass({
    render() {
        return (
            <div>
                <Header />
                <Body />
            </div>
        )
    }
});

|||-------------------------------------||||||

We must add the `<AllItems />` and `<NewItem />` components into the body component, just like we included. In the `<Body />` component, we’ll include the rest of the nested components, respectively:
...
Debemos agregar los componentes `<AllItems />` y `<NewItem />` en el componente body, tal como lo hemos incluido. En el componente `<Body />`, incluiremos el resto de los componentes anidados, respectivamente:


|||-------------------------------------||||||javascript
// app/assets/javascripts/components/_body.js.jsx

var Body = React.createClass({
    render() {
        return (
            <div>
                <NewItem />
                <AllItems />
            </div>
        )
    }
});


|||-------------------------------------||||||

Great! You should now see all the items displayed.
...
¡Estupendo! Ahora debería ver todos los elementos que se muestran.

Adding a new item
--

Time to move on to the next file we created previously; 
...
Es hora de pasar al siguiente archivo que creamos anteriormente;



|||-------------------------------------||||||javascript
//app/assets/javascripts/components/_new_item.js.jsx

var NewItem= React.createClass({
    render() {
        return (
            <div>
                <h1>new item</h1>
            </div>
        )
    }
});
|||-------------------------------------||||||



What’s needed to create a new item? We must create two input fields and send them to the server via POST request. When the new item is created, we have to reload our list of items so that they include the newly created one.
...
¿Qué se necesita para crear un nuevo elemento? Debemos crear dos campos de entrada y enviarlos al servidor a través de la petición POST. Cuando se crea el nuevo elemento, tenemos que volver a cargar nuestra lista de elementos para que incluyan el nuevo creado.

Let’s add the form fields and the button to handle the submission.
...
Añadamos los campos del formulario y el botón para manejar el envío.


|||-------------------------------------||||||javascript
// app/assets/javascripts/components/_new_item.js.jsx

var NewItem= React.createClass({
    render() {
        return (
            <div>

                <input ref='name' placeholder='Enter the name of the item' />
                <input ref='description' placeholder='Enter a description' />
                  <button>Submit</button>
              </div>
              )

        )
    }
});

|||-------------------------------------||||||


Everything looks familiar, except for the ref attribute. The ref attribute is used to reference the element in the component. Its function is similar to the `name` attribute in AngularJS. Instead of finding elements by id or by class, we do it by ref. In this particular case, the ref will be used to get the value of the text field and send it to the server.
...
Añadamos los campos del formulario y el botón para manejar el envío.


If you tried to click the `submit` button, you’ll notice that nothing happens. So let’s add an event handler! To do this, we need to slightly alter the html of the button:
...
Si intentas hacer clic en el botón `submit`, notarás que no pasa nada. Así que vamos a añadir un controlador de eventos! Para hacer esto, necesitamos alterar ligeramente el html del botón:

|||-------------------------------------||||||javascript
<button onClick={this.handleClick}>Submit</button>

|||-------------------------------------||||||

Once we have this, when we click the button the component will look for the `handleClick()` function. We must define it in the JavaScript file.
...
Una vez que tengamos esto, al hacer clic en el botón, el componente buscará la función `handleClick ()`. Debemos definirlo en el archivo JavaScript.


|||-------------------------------------||||||javascript
// app/assets/javascripts/components/_new_item.js.jsx

// var NewItem = …
handleClick() {
    var name    = this.refs.name.value;
    var description = this.refs.description.value;
    
   console.log('The name value is ' + name + 'the description value is ' + description);


},

//render()..


|||-------------------------------------||||||

This time, if you put text in the input fields and you click the button, it will print out the values of the input fields in the JavaScript console. Here you can see how the refs attribute is used in order to get the value out of the input field. Instead of sending the values to the console, we’re going to send them to the server. Here’s how this will happen: 
...
Esta vez, si coloca texto en los campos de entrada y hace clic en el botón, imprimirá los valores de los campos de entrada en la consola de JavaScript. Aquí puede ver cómo se utiliza el atributo refs para obtener el valor del campo de entrada. En lugar de enviar los valores a la consola, los vamos a enviar al servidor. Así es como esto sucederá:


|||-------------------------------------||||||javascript
// app/assets/javascripts/components/_new_item.js.jsx

var NewItem= React.createClass({
    handleClick() {
        var name    = this.refs.name.value;
        var description = this.refs.description.value;
        $.ajax({
            url: '/api/v1/items',
            type: 'POST',
            data: { item: { name: name, description: description } },
            success: (response) => {
                console.log('it worked!', response);
            }
        });
    },
    render() {
        return (
                <div>
                    <input ref='name' placeholder='Enter the name of the item' />
                    <input ref='description' placeholder='Enter a description' />
                    <button onClick={this.handleClick}>Submit</button>
                </div>

        )
    }
});

|||-------------------------------------||||||

We send a `POST` request to the URL endpoint for the items using `$.ajax` . The response contains an object with the item’s name and description. Its callback prints the response from the server in the console. Try it out!
...
Enviamos una solicitud `POST` al punto final de URL para los elementos que usan` $ .ajax`. La respuesta contiene un objeto con el nombre y la descripción del elemento. Su devolución de llamada imprime la respuesta del servidor en la consola. ¡Pruébalo!

Everything goes well, but there seems to be a problem: We have to restart the page in order to see the new item. How can we make this better?  `<NewItem />` and `<AllItems />` cannot communicate between each other because they’re on the same level. As we know, we can send data only down the component hierarchy. This means that we have to move the storing of the items of the `<AllItems />` state to an upper layer; we must move it to the `<Body />` component. 
...
Todo va bien, pero parece que hay un problema: Tenemos que reiniciar la página para ver el nuevo elemento. ¿Cómo podemos mejorar esto? `<NewItem />` y `<AllItems />` no pueden comunicarse entre sí porque están en el mismo nivel. Como sabemos, sólo podemos enviar datos en la jerarquía de componentes. Esto significa que tenemos que mover el almacenamiento de los elementos del estado `<AllItems />` a una capa superior; Debemos moverlo al componente `<Body />`.

Move `getInitialState()` and `componentDidMount()` from `<Allitems />` to `<Body />`. Now, the items will be fetched when `<Body />` is loaded. We can send variables down the children components with `props`. Props are immutable in the child and, in order to reach them, we need to use `this.props`. In our case, instead of using `this.state.items`, we’ll use `this.props.items`. 
...
Mueva `getInitialState ()` y `componentDidMount ()` desde `<Allitems />` a `<Body />`. Ahora, los elementos se obtendrán cuando se cargue `<Body />`. Podemos enviar variables a los componentes de los niños con `props`. Los accesorios son inmutables en el niño y, para alcanzarlos, necesitamos usar `this.props`. En nuestro caso, en lugar de usar `this.state.items`, usaremos` this.props.items`.


Here’s how we’ll send down the items from `<Body />` to `<AllItems />` :
...
Así es como enviaremos los elementos de `<Body />` a `<AllItems />`:

|||-------------------------------------||||||javascript
// app/assets/javascripts/components/_body.js.jsx

<AllItems items={this.state.items} /> 
|||-------------------------------------||||||

Here’s how they’re going to be referenced in  `<AllItems />` :

|||-------------------------------------||||||javascript
// app/assets/javascripts/components/_all_items.js.jsx

var items= this.props.items.map((item) => {

|||-------------------------------------||||||


We can also pass functions as properties down the components hierarchy. Let’s do that with `handleSubmit()` in `<NewItem />`. Just like the items array, we’ll move the function to its parent `<Body />` component as well.
...
También podemos pasar funciones como propiedades a la jerarquía de componentes. Hagamos eso con `handleSubmit ()` en `<NewItem />`. Al igual que la matriz de elementos, también moveremos la función a su componente `` Body /> ``.


|||-------------------------------------||||||javascript
// app/assets/javascripts/components/_body.js.jsx

// getInitialState() and componentDidMount()

    handleSubmit(item) {
        console.log(item);
    },

// renders the AllItems and NewItem component


|||-------------------------------------||||||
Then, let’s reference the function in the child component, just like we did with the array:
...
Entonces, vamos a hacer referencia a la función en el componente hijo, al igual que lo hicimos con la matriz:


|||-------------------------------------||||||javascript
// app/assets/javascripts/components/_body.js.js

<NewItem handleSubmit={this.handleSubmit}/>

|||-------------------------------------||||||

In the `<NewItem />` component, we’ll pass the function as part of `this.props` and pass on the object from the AJAX request as an argument of the parent:
...
En el componente `<NewItem />`, pasaremos la función como parte de `this.props` y pasaremos el objeto de la petición AJAX como un argumento del padre:


|||-------------------------------------||||||javascript
// app/assets/javascripts/components/_new_item.js.jsx

handleClick() {
    var name    = this.refs.name.value;
    var description = this.refs.description.value;
    $.ajax({
        url: '/api/v1/items',
        type: 'POST',
        data: { item: { name: name, description: description } },
        success: (item) => {
            this.props.handleSubmit(item);
        }
    });
}


|||-------------------------------------||||||

Now, when you click the submit button, the JavaScript console will log the object we just created. Awesome! We’re almost there. We just need to add the new item to the items array instead of logging it to the console.
...
Ahora, al hacer clic en el botón Enviar, la consola de JavaScript registrará el objeto que acabamos de crear. ¡Increíble! Casi estámos allí. Sólo tenemos que añadir el nuevo elemento a la matriz de elementos en lugar de registrarlo en la consola.


|||-------------------------------------||||||javascript
// app/assets/javascripts/components/_body.js.jsx

// getInitialState() and componentDidMount()

    handleSubmit(item) {
        var newState = this.state.items.concat(item);
        this.setState({ items: newState })
    },

// renders the AllItems and NewItemcomponent

|||-------------------------------------||||||


Everything should now be working right. Since a lot of code was moved in this step, here are the updated files, so that you can check if you have followed through correctly:
...
Ahora todo debería estar funcionando bien. Dado que un montón de código se ha movido en este paso, aquí están los archivos actualizados, para que pueda comprobar si ha seguido correctamente:


|||-------------------------------------||||||javascript
// app/assets/javascripts/components/_all_items.js.jsx

var AllItems = React.createClass({
    render() {
        var items= this.props.items.map((item) => {
            return (
                <div key={item.id}>
                    <h3>{item.name}</h3>
                    <p>{item.description}</p>
                </div>
            )
        });

        return(
            <div>
                {items}
            </div>
        )
    }
});

|||-------------------------------------||||||



|||-------------------------------------||||||javascript
// app/assets/javascripts/components/_body.js.jsx

var Body = React.createClass({
    getInitialState() {
        return { items: [] }
    },


    componentDidMount() {
        $.getJSON('/api/v1/items.json', (response) => { this.setState({ items: response }) });
    },



    handleSubmit(item) {
        var newState = this.state.items.concat(item);
        this.setState({ items: newState })
    },



    render() {
        return (
            <div>
                <NewItem handleSubmit={this.handleSubmit}/>
                <AllItems  items={this.state.items} />
            </div>
        )
    }
});
|||-------------------------------------||||||



|||-------------------------------------||||||javascript
// app/assets/javascripts/components/_new_item.js.jsx

var NewItem= React.createClass({
    handleClick() {
        var name    = this.refs.name.value;
        var description = this.refs.description.value;
        $.ajax({
            url: '/api/v1/items',
            type: 'POST',
            data: { item: { name: name, description: description } },
            success: (item) => {
                this.props.handleSubmit(item);
            }
        });
    },
    render() {
        return (
                <div>
                    <input ref='name' placeholder='Enter the name of the item' />
                    <input ref='description' placeholder='Enter a description' />
                    <button onClick={this.handleClick}>Submit</button>
                </div>

        )
    }
});

|||-------------------------------------||||||


Deleting an item
...
Eliminación de un elemento
--

Deleting items is similar to creating new ones. The first thing we need to do is to add a button and a function (for handling the click for deleting an item in the `<AllItems />` component).
...
La eliminación de elementos es similar a la creación de nuevos. Lo primero que debemos hacer es agregar un botón y una función (para manejar el clic para eliminar un elemento del componente `<AllItems />`).


|||-------------------------------------||||||javascript
// app/assets/javascripts/components/_all_items.js.jsx

var AllItems = React.createClass({
    handleDelete() {
        console.log('delete item clicked');
    },

    render() {
        var items= this.props.items.map((item) => {
            return (
                <div key={item.id}>
                    <h3>{item.name}</h3>
                    <p>{item.description}</p>
                    <button onClick={this.handleDelete}>Delete</button>
                </div>
            )
        });

        return(
            <div>
                {items}
            </div>
        )
    }
});

|||-------------------------------------||||||

Second, we’re going to pass the reference to the function up to the parent `<Body />` component, where the update of the list will be handled when the delete button is clicked.
...
En segundo lugar, vamos a pasar la referencia a la función hasta el componente `` <Body /> `, donde la actualización de la lista se manejará cuando se haga clic en el botón Eliminar.


|||-------------------------------------||||||javascript
// app/assets/javascripts/components/_body.js.jsx

    handleDelete() {
        console.log('in handle delete');
    },




    render() {
        return (
            <div>
                <NewItem handleSubmit={this.handleSubmit}/>
                <AllItems  items={this.state.items} handleDelete={this.handleDelete}/>
            </div>
        )
    }
});

|||-------------------------------------||||||

Now we’ll just pass the reference of the function in the parent component to the child component via `props` :
...
Ahora pasaremos la referencia de la función en el componente padre al componente secundario a través de `props`:


|||-------------------------------------||||||javascript
// app/assets/javascripts/components/_all_items.js.jsx

var AllItems = React.createClass({
    handleDelete() {
        this.props.handleDelete();
    },

    render() {
    //the rest of the component
|||-------------------------------------||||||



It all looks good, but how do we know which item we’re deleting?  We’re going to use the `bind()` method. The `bind()` method will bind the `id` of the item to `this`, causing the id to send as an argument.
...
Todo parece bueno, pero ¿cómo sabemos qué elemento estamos eliminando? Vamos a usar el método `bind ()`. El método `bind ()` unirá el `id` del elemento a` this`, haciendo que el id se envíe como un argumento.


|||-------------------------------------||||||javascript
// app/assets/javascripts/components/_all_items.js.jsx

handleDelete(id) {
    this.props.handleDelete(id);
},

render() {
    var items= this.props.items.map((item) => {
        return (
            <div key={item.id}>
                <h3>{item.name}</h3>
                <p>{item.description}</p>
                <button onClick={this.handleDelete.bind(this, item.id)} >Delete</button>
            </div>
        )
    });

|||-------------------------------------||||||


Now that we can send the id as an argument, we’re done with the second step. The third thing we need to do is to make an AJAX call to delete the item from the database. 
...
Ahora que podemos enviar el ID como un argumento, hemos terminado con el segundo paso. La tercera cosa que debemos hacer es hacer una llamada AJAX para eliminar el elemento de la base de datos

|||-------------------------------------||||||javascript
// app/assets/javascripts/components/_body.js.jsx

handleDelete(id) {
    $.ajax({
        url: `/api/v1/items/${id}`,
        type: 'DELETE',
        success(response) {
            console.log('successfully removed item')
        }
    });
},

|||-------------------------------------||||||


Everything works, but we’re encountering the same problem we had with adding a new item; the page has to be restarted in order to see the results. Our last step is to change that; we will update the state by removing the item from the array of items upon successful deletion from the database. 
...
Todo funciona, pero estamos encontrando el mismo problema que tuvimos al agregar un nuevo elemento; La página debe ser reiniciada para ver los resultados. Nuestro último paso es cambiar esto; Actualizaremos el estado eliminando el elemento de la matriz de elementos al eliminarlo con éxito de la base de datos.

|||-------------------------------------||||||javascript
// app/assets/javascripts/components/_body.js.jsx

handleDelete(id) {
    $.ajax({
        url: `/api/v1/items/${id}`,
        type: 'DELETE',
        success:() => {
           this.removeItemClient(id);
        }
    });
},

removeItemClient(id) {
    var newItems = this.state.items.filter((item) => {
        return item.id != id;
    });

    this.setState({ items: newItems });
},


|||-------------------------------------||||||

Remember to change the syntax of the `success` function from `success (response) {}` to `success: () => {}`, otherwise you’ll be referring to the promise of the response instead of the component itself.
...
Recuerde cambiar la sintaxis de la función `success` de` success (response) {} `a` success: () => {} `, de lo contrario se referirá a la promesa de la respuesta en lugar del componente en sí.

Editing an item
...
Edición de un elemento
--

The last thing we’re going to do is implement editing and updating of items. We’ll add an edit button and a listener for it. When the edit button is clicked, the item will enter into `edit` mode in which the text attributes will turn into text fields. When the changes are submitted, an AJAX request will be made and, if it is successful, the item will be saved with the new attributes.
...
Lo último que vamos a hacer es implementar la edición y actualización de los elementos. Agregaremos un botón de edición y un oyente para él. Cuando se hace clic en el botón de edición, el elemento entrará en modo `edit` en el que los atributos de texto se convertirán en campos de texto. Cuando se envían los cambios, se realizará una solicitud AJAX y, si tiene éxito, el elemento se guardará con los nuevos atributos.

First, we’ll implement the edit button and its event listener.
...
En primer lugar, implementaremos el botón de edición y su detector de eventos.

|||-------------------------------------||||||javascript
// app/assets/javascripts/components/_all_items.js.jsx

handleEdit() {

},
//render() and the rest of the tempalte
<button onClick={this.handleEdit()}> Edit </button>

|||-------------------------------------||||||

With the editing mode, the code for a singular item will become too much, and following the rule of separation of concerns, we’ll have to move it to a separate component, which will be named <Item/>. This component will be used to contain the information and methods for a single item. The `handleEdit()` and `handleDelete()` functions will be referenced as properties of the component and, as such, will be referenced using the `this.props.*` notation.
...
Con el modo de edición, el código de un elemento singular se volverá demasiado, y siguiendo la regla de separación de las preocupaciones, tendremos que moverlo a un componente separado, que se llamará <Item />. Este componente se utilizará para contener la información y los métodos para un solo artículo. Las funciones `handleEdit ()` y `handleDelete ()` serán referenciadas como propiedades del componente y, como tales, serán referenciadas usando la notación `this.props. *`.


|||-------------------------------------||||||javascript
// app/assets/javascripts/components/_all_items.js.jsx

render() {
    var items= this.props.items.map((item) => {
        return (
            <div key={item.id}>
                <Item item={item}
                       handleDelete={this.handleDelete.bind(this, item.id)}
                       handleEdit={this.handleEdit}/>
            </div>
        )
    });

|||-------------------------------------||||||


Here’s how the `<Item />` template will look:


|||-------------------------------------||||||javascript
// app/assets/javascripts/components/_item.js.jsx

var Item = React.createClass({
    render() {
        return (
            <div>
                <h3>{this.props.item.name}</h3>
                <p>{this.props.item.description}</p>
                <button onClick={this.props.handleDelete} >Delete</button>
                <button onClick={this.props.handleEdit}> Edit </button>
            </div>
        )
    }
});

|||-------------------------------------||||||



The html markup is similar to the one we used previously, but the attributes and the functions are accessed via `this.props`, since they were referenced as properties of the template. Now, test out the functionality to be sure everything works.
...
El marcado html es similar al que usamos anteriormente, pero los atributos y las funciones se acceden a través de `this.props`, ya que fueron referenciados como propiedades de la plantilla. Ahora, pruebe la funcionalidad para asegurarse de que todo funcione.

Next, we’ll move `handleEdit()` to the `<Item />` template. We’ll have a Boolean variable which we’ll toggle by clicking on the button. If the variable is set to true, the text is converted to input fields and vice versa.
...
A continuación, moveremos `handleEdit ()` a la plantilla `<Item />`. Tendremos una variable booleana que vamos a cambiar haciendo clic en el botón. Si la variable se establece en true, el texto se convierte en campos de entrada y viceversa.

Let’s move the `handleEdit()` to `<Item />`. We can simply do this by writing the method inside the component and changing the property of the button from `this.props.handleEdit` to `this.handleEdit`.
...
Vamos a mover el `handleEdit ()` a `<Item />`. Simplemente podemos hacer esto escribiendo el método dentro del componente y cambiando la propiedad del botón de `this.props.handleEdit` a` this.handleEdit`.


|||-------------------------------------||||||javascript
// _app/assets/javascripts/components/_item.js.jsx
<button onClick={this.handleEdit}> Edit </button>

|||-------------------------------------||||||


And initialize the method into the component:
...
E inicialice el método en el componente:


|||-------------------------------------||||||javascript
// app/assets/javascripts/components/_item.js.jsx

var Item = React.createClass({
    handleEdit() {
        console.log('edit button clicked')
    },


|||-------------------------------------||||||

Now, we’ll have a state variable named editable `this.state.editable` that we’ll set to `false` initially, and set to `true` if the edit button is clicked.
...
Ahora, tendremos una variable de estado llamada editable `this.state.editable` que inicialmente estableceremos como` false` y estableceremos `true` si se hace clic en el botón de edición.


|||-------------------------------------||||||javascript
// app/assets/javascripts/components/_item.js.jsx

var Item = React.createClass({
    getInitialState() {
        return {editable: false}
    },
    handleEdit() {
        this.setState({editable: !this.state.editable})
    },

    render() {

|||-------------------------------------||||||


A ternary operator must be implanted; this will render different elements depending whether `this.state.editable` is set to `true` or `false`. Here’s how to do that:
...
Se debe implantar un operador ternario; Esto hará que diferentes elementos dependan de si `this.state.editable` se establece en` true` o `false`. A continuación, le indicamos cómo hacerlo:


|||-------------------------------------||||||javascript
// app/assets/javascripts/components/_item.js.jsx

render() {
    var name = this.state.editable ? <input type='text' defaultValue={this.props.item.name} /> : <h3>{this.props.item.name}</h3>;
    var description = this.state.editable ? <input type='text' defaultValue={this.props.item.description} />: <p>{this.props.item.description}</p>;
    return (
        <div>
            {name}
            {description}
            <button onClick={this.props.handleDelete} >Delete</button>
            <button onClick={this.handleEdit}> Edit </button>
 …


|||-------------------------------------||||||
The name and description variable are now dynamic; they will change depending on `this.state.editable`. Let’s do the same for the edit button:
...
El nombre y la variable de descripción son ahora dinámicos; Cambiarán dependiendo de `this.state.editable`. Hagamos lo mismo con el botón de edición:


|||-------------------------------------||||||javascript
// app/assets/javascripts/components/_item.js.jsx

<button onClick={this.handleEdit}> {this.state.editable ? 'Submit' : 'Edit' } </button>
|||-------------------------------------||||||

There’s something missing in the input fields. We’ll reference them in the component methods just as we did in `<NewItem />`; there has to be a `ref` attribute in the input fields. Let’s add this attribute to the input fields and reference them in the `handleEdit()` method.
...
Hay algo que falta en los campos de entrada. Los haremos referencia en los métodos de componentes tal como lo hicimos en `<NewItem />`; Tiene que haber un atributo `ref` en los campos de entrada. Vamos a agregar este atributo a los campos de entrada y hacer referencia a ellos en el método `handleEdit ()`.

|||-------------------------------------||||||javascript
// app/assets/javascripts/components/_item.js.jsx

render() {
    var name = this.state.editable ? <input type='text' ref='name' defaultValue={this.props.item.name} /> : <h3>{this.props.item.name}</h3>;
    var description = this.state.editable ? <input type='text' ref='description' defaultValue={this.props.item.description} />: <p>{this.props.item.description}</p>;


|||-------------------------------------||||||

Now, add the code to reference the input fields in the method:
...
Ahora, agregue el código para hacer referencia a los campos de entrada en el método:

|||-------------------------------------||||||javascript
// app/assets/javascripts/components/_item.js.jsx

handleEdit() {
    if(this.state.editable) {
        var name = this.refs.name.value;
        var description = this.refs.description.value;
        console.log('in handleEdit', this.state.editable, name, description);

    }
    this.setState({ editable: !this.state.editable })
},

|||-------------------------------------||||||


Open your JavaScript console and try entering values into an item. Once you click the submit button, you will see the values displayed on the screen. We have the values in `<Item />` and we have to send them up to the `<Body />` where the array with all the items is stored and where we’re going to call our server. This means that we’ll use props functions to pass the data up the chain. The journey will start with `<Item />`, pass to `<AllItems />` and end up in `<Body />`. Let’s start with `<Item />` to `<AllItems />`:
...
Abra su consola de JavaScript e intente introducir valores en un elemento. Una vez que haga clic en el botón Enviar, verá los valores mostrados en la pantalla. Tenemos los valores en `<Item />` y tenemos que enviarlos al `<Body />` donde se almacena la matriz con todos los elementos y donde vamos a llamar a nuestro servidor. Esto significa que usaremos las funciones de los apoyos para pasar los datos a la cadena. El viaje comenzará con `<Item />`, pasará a `<AllItems />` y terminará en `<Body />`. Empecemos con `<Item />` a `<AllItems />`:

|||-------------------------------------||||||javascript
// app/assets/javascripts/components/_item.js.jsx

handleEdit() {
    if(this.state.editable) {
        var name = this.refs.name.value;
        var id = this.props.item.id;
        var description = this.refs.description.value;
        var item = {id: id , name: name , description: description};
        this.props.handleUpdate(item);

    }
    this.setState({ editable: !this.state.editable })
},


|||-------------------------------------||||||

In `<AllItems />` we’ll add a `handleUpdate` method that will take the properties set in `onUpdate` and will pass these up to its own `onUpdate` property:
...
En `<AllItems />` añadiremos un método `handleUpdate` que tomará las propiedades establecidas en` onUpdate` y las pasará a su propia propiedad `onUpdate`:

|||-------------------------------------||||||javascript
// app/assets/javascripts/components/_all_items.js.jsx

onUpdate(item) {
    this.props.onUpdate(item);
},

render() {
    var items= this.props.items.map((item) => {
        return (
            <div key={item.id}>
                <Item item={item}
                      handleDelete={this.handleDelete.bind(this, item.id)}
                      handleUpdate={this.onUpdate}/>
            </div>
        )
    });


|||-------------------------------------||||||


Finally, `<Body />` will take the `onUpdate` property of `<AllItems />` with the item in it.
...
Finalmente, `<Body />` tomará la propiedad `onUpdate` de` <AllItems /> `con el elemento en él.

|||-------------------------------------||||||javascript
// app/assets/javascripts/components/_body.js.jsx

handleUpdate(item) {
    $.ajax({
            url: `/api/v1/items/${item.id}`,
            type: 'PUT',
            data: { item: item },
            success: () => {
                console.log('you did it!!!');
                //this.updateItems(item);
                // callback to swap objects
            }
        }
    )},


render() {
    return (
        <div>
            <NewItem handleSubmit={this.handleSubmit}/>
            <AllItems  items={this.state.items}  handleDelete={this.handleDelete} onUpdate={this.handleUpdate}/>
        </div>
    )
}

    )},


|||-------------------------------------||||||
As you can see, we’ve managed to send the item up the components. (Note: Make sure the names of your function in the properties of the components are correct so that everything flows nicely.)
...
Como puede ver, hemos logrado enviar el elemento a los componentes. (Nota: Asegúrese de que los nombres de su función en las propiedades de los componentes son correctos para que todo fluya bien).

The last thing that must be done in order to finish the functionality is to add a method in `<Body />` to replace the newly updated item with the old one in the items array.
...
Lo último que se debe hacer para terminar la funcionalidad es agregar un método en `<Body />` para reemplazar el elemento recién actualizado con el antiguo en la matriz items.


|||-------------------------------------||||||javascript
// app/assets/javascripts/components/_body.js.jsx

handleUpdate(item) {
    $.ajax({
            url: `/api/v1/items/${item.id}`,
            type: 'PUT',
            data: { item: item },
            success: () => {
                this.updateItems(item);

            }
        }
    )},

updateItems(item) {
    var items = this.state.items.filter((i) => { return i.id != item.id });
    items.push(item);

    this.setState({items: items });
},
|||-------------------------------------||||||



That’s it! We managed to implement a full CRUD functionality for one model. Now you can improve your project by adding some styles to it or adding some extra information to the items themselves. [Here’s the github repository of the project we just created](https://github.com/Kaizeras/react-rails-tutorial).
...
¡Eso es! Hemos logrado implementar una funcionalidad CRUD completa para un modelo. Ahora usted puede mejorar su proyecto añadiendo algunos estilos a él o añadiendo una cierta información adicional a los artículos ellos mismos. [Aquí está el repositorio github del proyecto que acabamos de crear] (https://github.com/Kaizeras/react-rails-tutorial).

If you’d like to learn more about React with Rails, you can check out the official git repository of react-rails.  Or, if you’d like to learn more about React in general, you can check out its documentation. If you have any questions, you can message me in our [community slack](https://hackguides.herokuapp.com/).
...
Si desea obtener más información sobre React with Rails, puede consultar el repositorio oficial de git de react-rails. O, si desea obtener más información sobre React en general, puede consultar su documentación. Si tiene alguna pregunta, puede enviarme un mensaje en nuestra [holgura de la comunidad] (https://hackguides.herokuapp.com/).
