use strict;
use warnings;
use Scalar::Util qw(looks_like_number);
use DBI;

my $host      = '*****';
my $port      = "*****";
my $user     = "*****";
my $password = "*****";

# Устанавливаем соединение с БД
my $dsn      = "DBI:mysql:database=task_regru;host=$host;port=$port";
my $dbh = DBI->connect ($dsn, $user, $password) or die "Не удалось установить соединение с базой данных: " . DBI->errstr();


# Проверяем существование таблиц и создаём их

my @tables;
my $sql_show_tables = $dbh->prepare("show tables;");
$sql_show_tables->execute();

while (my $table = $sql_show_tables->fetchrow_array() ) {

push @tables, $table;

};

if ( not(grep( /^contacts$/, @tables )) ) {
    
my $sql_create_table_contacts = <<'END_SQL';
CREATE TABLE contacts (
  id            INTEGER NOT NULL AUTO_INCREMENT,
  fname         VARCHAR(100) NOT NULL,
  lname         VARCHAR(100) NOT NULL,
  patronymic    VARCHAR(100),
  primary key (id)
);
END_SQL
$dbh->do($sql_create_table_contacts);

}

if ( not(grep( /^phone_numbers$/, @tables )) ) {

my $sql_create_table_phone_numbers = <<'END_SQL';
CREATE TABLE phone_numbers (
  id            INTEGER NOT NULL AUTO_INCREMENT,
  contact_id    INTEGER NOT NULL,
  phone         VARCHAR(100) UNIQUE NOT NULL,
  type_phone    VARCHAR(100) NOT NULL,
  primary key (id)
);
END_SQL
$dbh->do($sql_create_table_phone_numbers);

}

# Выводим меню

(my $start_message = qq{
    Замечательная телефонная книжка!

    Выбери дальнейшее действие: 

    1) Показать все контакты;
    2) Добавить контакт;
    3) Удалить контакт;
    4) Изменить контакт.
}) =~ s/^ {4}//mg;

    print $start_message;

while (42) {
    

    my $choice = <STDIN>;
    chomp $choice;

    if (looks_like_number($choice)) {
        if ( $choice == 1 ) {
            print "Вы выбрали 1 => Показать все контакты\n";
            last;
        } elsif ( $choice == 2 ) {
            print "Вы выбрали 2 => Добавить контакт\n";
            last;
        } elsif ( $choice == 3 ) {
            print "Вы выбрали 3 => Удалить контакт\n";
            last;
        } elsif ( $choice == 4 ) {
            print "Вы выбрали 4 => Изменить контакт\n";
            last;
        } else {
            print "Такого варианта нет. Попробуй ещё раз\n"
        }
} else {
    print "Введённое значение не является числом. Попробуй ещё раз\n"
}

}