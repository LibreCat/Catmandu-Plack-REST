package Catmandu::Plack::Restify;

use Moo;
use Catmandu;
use Catmandu::Sane;
use Plack::Request;
use Plack::Response;
use parent qw( Plack::Component );
use JSON;

has strict => ( is => 'ro', default => sub { 1 } );
has resources => ( is => 'ro' );

sub call {
  my ($self, $env) = @_;
  my $req = Plack::Request->new($env);

  my $data;
  my $err;

  eval {
    $data = $self->_handle($req);
  } or do {
    $err = $@;
  };

  my $status;
  my $json;

  if ($err) {
    $status = 500;
    $json = encode_json( { error => $err } );
  } else {
    $status = $self->_status_code($req, $data);
    $json = $data ? encode_json($data) : '';
  }

  my $res = $self->_response($status, $json);

  return $res;
}

sub _handle {
  my ($self, $req) = @_;
  my $out;
  my $method = $req->method;
  my $path = substr($req->path, 1);

  my @a = split(/\//, $path);
  $self->{collection} = $a[0];
  my $id = $a[1];

  my $mode = $self->_mode($id);

  # GET /
  if ($path eq '') {
    $out = {
      'Catmandu::Plack::Restify' => 'is running!'
    };
  }

  # GET /quotes/search/query
  if ($method eq 'GET' && $mode eq 'search' && $self->_store_is_searchable) {
    my $query = $a[2];
    $out = $self->_search($query);
  }

  # GET /quotes
  if ($method eq 'GET' && $mode eq 'collection') {
    $out = $self->_list;
  }

  # GET /quotes/1
  if ($method eq 'GET' && $mode eq 'resource') {
    $out = $self->_get($id);
  }

  # POST /quotes
  if ($method eq 'POST' && $mode eq 'collection') {
    my $data = decode_json( $req->content );
    $out = $self->_add($data);
  }

  # PUT /quotes/1
  if ($method eq 'PUT' && $mode eq 'resource') {
    my $data = decode_json( $req->content );
    $out = $self->_update($id, $data);
  }

  # DEL /quotes/1
  if ($method eq 'DEL' && $mode eq 'resource') {
    $out = $self->_delete($id);
  }

  return $out;
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
  my $out;

  # state %STATUS = {
  #   200 => 'OK',
  #   201 => 'Created',
  #   204 => 'No Content',
  #   400 => 'Bad Request',
  #   404 => 'Not Found',
  #   405 => 'Method Not Allowed',
  #   500 => 'Internal Server Error'
  # };

  given($req->method) {
    when('GET') {
      $out = $data ? 200 : 404;
    }
    when ('POST') {
      $out = 201;
    }
    when ('PUT') {
      $out = 200;
    }
    when ('DEL') {
      $out = $data ? 204 : 500;
    }
  }

  return $out;
}

# store related. ---------------------------------------------------------------

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

  while ($i <= $#collection && $collection[$i] ne $value ) {
    ++$i;
  }

  if ($i <= $#collection) {
    return 1;
  }

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
