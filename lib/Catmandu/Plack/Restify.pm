package Catmandu::Plack::Restify;

use Moo;
use Catmandu;
use Catmandu::Sane;
use Catmandu::Util qw( :is );
use Plack::Request;
use Plack::Response;
use parent qw( Plack::Component );
use JSON;

# options.

has strict => (
  is => 'ro',
  default => sub { 1 }
);

has resources => (
  is => 'ro'
);

has readonly => (
  is => 'ro',
  default => sub { 0 }
);

# override.

sub call {
  my ($self, $env) = @_;

  my $req = Plack::Request->new($env);
  my $data = $self->_handle($req);
  my $status = $self->_status_code($req, $data);
  my $json = $data ? encode_json($data) : '';
  my $res = $self->_response($status, $json);

  return $res;
}

# internal.

sub _handle {
  my ($self, $req) = @_;

  # http method
  my $method = $req->method;

  # parse path
  my $path = substr($req->path, 1);
  my @a = split(/\//, $path);
  $self->{collection} = $a[0];
  my $id = $a[1];

  # collection, resource or search mode?
  my $mode = $self->_mode($id);

  # GET /
  if ( $path eq '' ) {
    return { '200' => 'OK' };
  }

  # GET /quotes/search/query
  if ( ( $method eq 'GET' or $method eq 'HEAD' ) && $mode eq 'search' && $self->_store_is_searchable ) {
    my $query = $a[2];
    return $self->_search($query);
  }

  # GET /quotes
  if ( $method eq 'GET' && $mode eq 'collection' ) {
    return $self->_list;
  }

  # GET /quotes/1
  if ( $method eq 'GET' && $mode eq 'resource' ) {
    return $self->_get($id);
  }

  # POST /quotes
  if ( $method eq 'POST' && $mode eq 'collection' ) {
    return { '405' => 'Method Not Allowed' } if $self->readonly;

    my $data = decode_json( $req->content );
    return $self->_add($data);
  }

  # PUT /quotes/1
  if ( ( $method eq 'PUT' or $method eq 'PATCH' ) && $mode eq 'resource' ) {
    return { '405' => 'Method Not Allowed' } if $self->readonly;

    my $data = decode_json( $req->content );
    return $self->_update($id, $data);
  }

  # DEL /quotes/1
  if ( $method eq 'DEL' && $mode eq 'resource' ) {
    return { '405' => 'Method Not Allowed' } if $self->readonly;

    return $self->_delete($id);
  }

  # if we get here, no match was found.
  return { '400' => 'Bad Request' };
}

sub _mode {
  my ($self, $id) = @_;
  my $out = 'collection';

  if (defined $id) {
    if ($id ne '' && $id ne 'search') {
      $out = 'resource';
    } elsif ($id eq 'search') {
      $out = 'search';
    }
  }

  return $out;
}

sub _response {
  my ($self, $status, $body) = @_;

  my $res = Plack::Response->new;
  $res->status($status);
  $res->content_type('application/json');
  $res->body($body);
  $res->content_length(Plack::Util::content_length($body));

  return $res->finalize;
}

sub _status_code {
  my ($self, $req, $data) = @_;

 my %STATUS = (
    200 => 'OK',
    201 => 'Created',
    204 => 'No Content',
    400 => 'Bad Request',
    404 => 'Not Found',
    405 => 'Method Not Allowed',
    500 => 'Internal Server Error'
  );

  if ( is_hash_ref($data) ) {
    for ( keys %STATUS ) {
      return $_ if exists $data->{$_};
    }
  }

  given($req->method) {
    return $data ? 200 : 404 when [ 'GET', 'HEAD' ];
    return 201 when 'POST';
    return 200 when [ 'PUT', 'PATCH' ];
    return $data ? 204 : 500 when 'DEL';
  }

  # if we get here, no match was found.
  return { '400' => 'Bad Request' };
}

# store related.

sub _store {
  my ($self) = @_;
  $self->{store} = Catmandu->store('default') unless defined $self->{store};

  die "No collection specified."
    unless $self->{collection};

  if ($self->strict) {
    if (!$self->_exists($self->{collection}, @{$self->resources})) {
      die "Strict mode.";
    }
  }

  return $self->{store}->bag($self->{collection});
}

sub _exists {
  my ($self, $value, @collection) = @_;
  my $i = 0;
  while ($i <= $#collection && $collection[$i] ne $value ) { ++$i; }
  if ($i <= $#collection) { return 1; }
  return 0;
}

sub _store_is_searchable {
  my $self = $_[0];
  return $self->_store->does('Catmandu::Searchable');
}

sub _search {
  my ($self, $query) = @_;
  return $self->_store->search(query => $query)->to_array;
}

sub _get {
  my ($self, $id) = @_;
  return $self->_store->get($id);
}

sub _list {
  my ($self) = @_;
  return $self->_store->to_array;
}

sub _add {
  my ($self, $entity) = @_;
  $self->_store->add($entity);
  return $self->_store->commit;
}

sub _update {
  my ($self, $id, $entity) = @_;
  $entity->{_id} = $id;
  $self->_store->add($entity);
  return $self->_store->commit;
}

sub _delete {
  my ($self, $id) = @_;
  $self->_store->delete($id);
  return $self->_store->commit;
}

1;
