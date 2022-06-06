use strict;
use warnings;


package Animal {

    sub new {

        my $class = shift;

        my $self = {
            'name' => shift,
            'id' => shift
            };

        bless $self, $class;
        return $self;
    }

    sub Eat {
        print "Я питаюсь\n";
    }

    sub Move {
        print "Я двигаюсь\n"
    }
}

package Cat {

    use parent -norequire, 'Animal';
    use Moose;

    override Eat => sub {    
        print "Я кот, я хищник\n";
        super()
    }
}

my $tom = Cat->new("Том", 12541);
$tom->Eat();
$tom->Move()