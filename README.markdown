Rails Widget
============

A mini-framework for your client side Rails assets.


Getting started
---------------

## Layout

Place the following helper calls in your layout:

	<%= javascripts %>
	<%= stylesheets %>
	<%= templates %>

It is generally good practice to put `stylesheets` in the `<head>` tag, and `templates` at the bottom of the `<body>` tag, immediately followed by `javascripts`.

### Install a widget

### Require widget

### Render widget


Building your own widgets
-------------------------

A widget is a folder within **app/widgets** that can optionally contain any of the following files:

* options.rb
* flash/
* javascripts/
* partials/
* stylesheets/
* templates/

### options.rb

Contains a Hash of options that are passed to any file that is rendered within the widget.

Example:

	{
	  :id => 'example_widget',
	  :title => 'Example'
	}

Options can also be passed from the `render_widget` and `require_widget` calls, and take precedence over **options.rb**.

Example:

	render_widget :my_widget, { :id => 'my_widget' }


### flash/

Flash assets are copied to **public/flash/widgets** when created or modified. Use `widget_flash_path` to retrieve the asset path.

Example:

	widget_flash_path :my_widget, 'flash_asset.swf'

### javascripts/

Javascript assets are rendered (using **options.rb**) to **public/javascripts/widgets** when created or modified. Use `widget_flash_path` to  retrieve the asset path.


##### Copyright (c) 2008 Winton Welsh, released under the MIT license