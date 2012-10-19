Plack-App-Catmandu
------------------

# NOTES

-> Main pm file is responsible for reading configuration (creating store + serializer)
   and creating a Plack::Request object from the PSGI env hash.

-> Handler is responsible for mapping a Plack::Request object to the proper Store call.
    '-> uses Catmandu::Exporter's to serialize

-> Store is a adapter for a Catmandu::Store.

# API

  Plack::App::Catmandu->new(
    store => 'Catmandu::Store::ElasticSearch',
    serialize => 'Catmandu::Exporter::JSON',
  );

-> will use ElasticSearch as datastore.

-> will responde with JSON and 'application/json' content-type.

-> proper statuscodes (200, 201, 404, 500)

-> determine resources by the URL design.


# Plackup

http://advent.plackperl.org/2009/12/day-3-using-plackup.html
http://advent.plackperl.org/2009/12/day-4-reloading-applications.html
