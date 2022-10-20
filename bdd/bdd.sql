/************************************************************************ BDD ***************************************************************************/
/*******************************************************************************************************************************************************/

DROP database IF EXISTS bdd_ppe;
Create database bdd_ppe;
use bdd_ppe;

Create table client 
(
    idclient int(3) auto_increment,
    nom varchar(20) NOT NULL,
    siret varchar(14) NOT NULL unique,
    tel varchar(20) default NULL,
    email varchar(50) NOT NULL unique,
    adresse varchar(50) default NULL,
    CP varchar(5) default NULL,
    ville varchar(20) default NULL,
    role enum('userc', 'admin') default 'userc',
    mdp varchar(255) NOT NULL,
    PRIMARY KEY (idclient)
) 
ENGINE=innodb DEFAULT CHARSET=latin1;

Create table contrat
(
    num_contrat int(3) auto_increment,
    idclient int(3),
    date_souscription date NOT NULL,
    montant_mensuel_ht decimal(13,2) NOT NULL,
    etat_du_contrat enum('valide','resilier', 'en cours'),
    objet_du_contrat varchar(50) NOT NULL,
    PRIMARY KEY (num_contrat),
    foreign KEY (idclient) references client (idclient)
    on update cascade
    on delete cascade
)
ENGINE=innodb DEFAULT CHARSET=latin1;

Create table intervention
(
    num_intervention int(3) auto_increment,
    num_contrat int(3),
    date_heure_affectation datetime NOT NULL,
    etat_intervention enum('en cours','terminer','en suspend'),
    PRIMARY KEY (num_intervention,num_contrat),
    foreign KEY (num_contrat) references contrat (num_contrat)
    on update cascade
    on delete cascade 
)
ENGINE=innodb DEFAULT CHARSET=latin1;

Create table technicien
(
    idtechnicien int(3) auto_increment,
    nom varchar(20) NOT NULL,
    prenom varchar(20) NOT NULL,
    disponibilite enum('jour','nuit') NOT NULL,
    tarif_horaire decimal(13,2) NOT NULL,
    tel varchar(20) default NULL,
    email varchar(100) NOT NULL unique,
    role enum('usert', 'admin') default 'usert',
    mdp varchar(255) NOT NULL,
    PRIMARY KEY (idtechnicien)
)
ENGINE=innodb DEFAULT CHARSET=latin1;

Create table planning
(
    idtechnicien int(3),
    num_intervention int(3),
    date_heure_debut datetime NOT NULL,
    date_heure_fin datetime NOT NULL,
    PRIMARY KEY (idtechnicien,num_intervention,date_heure_debut),
    foreign KEY (idtechnicien) references technicien (idtechnicien)
    on update cascade
    on delete cascade,
    foreign KEY (num_intervention) references  intervention (num_intervention)
    on update cascade
    on delete cascade
)
ENGINE=innodb DEFAULT CHARSET=latin1;

Create table user 
(
    iduser int(3) auto_increment,
    nom varchar(20),
    prenom varchar(20),
    email varchar(255) unique,
    mdp varchar(255),
    role enum("admin", "userc", "usert"),
    primary key (iduser)
) 
ENGINE=innodb DEFAULT CHARSET=latin1;

create table resetpassword
(
    idresetpassword int(3) auto_increment,
    code varchar(255) NOT NULL,
    email varchar(255) NOT NULL,
    primary key(idresetpassword)
)
ENGINE=innodb DEFAULT CHARSET=latin1;


/*************************************************************************** VIEWS *****************************************************************************/
/**************************************************************************************************************************************************************/

create or replace view vlesContrats as (
select c.idclient, c.nom, c.siret, c.tel, c.email, c.adresse, c.ville, co.num_contrat, co.date_souscription, co.montant_mensuel_ht,
co.etat_du_contrat, co.objet_du_contrat
from client c, contrat co
where c.idclient = co.idclient
);


create or replace view vlesInterventionsContrats as (
select c.num_contrat, c.date_souscription, c.montant_mensuel_ht, c.etat_du_contrat,c.objet_du_contrat,
 i.num_intervention,i.date_heure_affectation, i.etat_intervention
from contrat c, intervention i
where c.num_contrat = i.num_contrat
);

create or replace view vlesPlannings as (
select t.idtechnicien, i.num_intervention, c.num_contrat, t.nom, t.prenom, p.date_heure_debut, p.date_heure_fin
from technicien t, planning p, intervention i, contrat c
where t.idtechnicien = p.idtechnicien and p.num_intervention = i.num_intervention and c.num_contrat =  i.num_contrat
);

create or replace view vlesNbContrats as (
select c.idclient, c.nom, count(co.num_contrat) nb_contrat
from client c, contrat co
where c.idclient = co.idclient
group by c.idclient
);

create or replace view vlesNbInterventions as (
select t.idtechnicien, t.nom, t.prenom, count(p.num_intervention) nb_intervention
from technicien t, planning p
where t.idtechnicien = p.idtechnicien
group by t.idtechnicien
);



/*************************************************************************** TRIGGERS *************************************************************************/
/*************************************************************************************************************************************************************/


/*** TRIGGERS CRYPTAGE CLIENT / TECHNICIEN / USER ***/


Drop trigger if exists beforeInsertClient;
Delimiter //
Create trigger beforeInsertClient
Before insert on client
For each row
Begin
    Set new.mdp = sha1(new.mdp);
    Set new.idclient = (select max(iduser) from user) +1;
End //
Delimiter ;


Drop trigger if exists beforeUpdateClient;
Delimiter //
Create trigger beforeUpdateClient
Before update on client
For each row
Begin
    Set new.mdp = sha1(new.mdp);
End //
Delimiter ;



Drop trigger if exists beforeInsertTechnicien;
Delimiter //
Create trigger beforeInsertTechnicien
Before insert on technicien
For each row
Begin
    Set new.mdp = sha1(new.mdp);
    Set new.idtechnicien = (select max(iduser) from user) +1;
End //
Delimiter ;


Drop trigger if exists beforeUpdateTechnicien;
Delimiter //
Create trigger beforeUpdateTechnicien
Before update on technicien
For each row
Begin
    Set new.mdp = sha1(new.mdp);
End //
Delimiter ;

/*********************************************/


/***** TRIGGER INSERT CLIENT TO USER *****/

drop trigger if exists insertclientuser;
delimiter //
CREATE TRIGGER insertclientuser
 after insert on client
 for each row
 begin
 insert into user (nom, email, mdp, role) values ( new.nom, new.email, new.mdp, new.role);
 END //
Delimiter ;

drop trigger if exists updateclientuser;
delimiter //
CREATE TRIGGER updateclientuser
after update on client
for each row
begin

update user
set  email = new.email, nom = new.nom, mdp = new.mdp, role = new.role
where iduser = old.idclient;
END //
Delimiter ;

drop trigger if exists deleteclientuser;
delimiter //
create trigger deleteclientuser
after delete on client
for each row
begin

delete from user
where iduser = old.idclient;
end //
delimiter ;

/*************************************/

/* TRIGGER INSERT TECHNICIEN TO USER*/

drop trigger if exists inserttechnicienuser;
delimiter //
CREATE TRIGGER inserttechnicienuser
 after insert on technicien
 for each row
 begin
 insert into user (nom, prenom, email, mdp, role) values (new.nom, new.prenom, new.email, new.mdp, new.role);
 END //
Delimiter ;

drop trigger if exists updatetechnicienuser;
delimiter //
CREATE TRIGGER updatetechnicienuser
after update on technicien
for each row
begin

update user
set  email = new.email, nom = new.nom, prenom = new.prenom , mdp = new.mdp, role = new.role
where iduser = new.idtechnicien;
END //
Delimiter ;

drop trigger if exists deletetechnicienuser;
delimiter //
create trigger deletetechnicienuser
after delete on technicien
for each row
begin

delete from user
where iduser = old.idtechnicien;
end //
delimiter ;

/**********************************************/

/************* TRIGGER RESET PASSWORD CLIENT ********/

drop trigger if exists resetpassclient;
delimiter //
create trigger resetpassclient
after insert on resetpassword
for each row
begin
if (new.email in (select email from client))
    then
        update client set mdp= new.code where new.email = email;
    end if;
end //
delimiter ;

/**********************************************/

/************* TRIGGER RESET PASSWORD TECHNICIEN ********/

drop trigger if exists resetpasstechnicien;
delimiter //
create trigger resetpasstechnicien
after insert on resetpassword
for each row
begin
if (new.email in (select email from technicien))
    then
        update technicien set mdp= new.code where new.email = email;
    end if;
end //
delimiter ;

/**********************************************/

/******************************************************************************************* EVENTS ******************************************************************************************************/
/********************************************************************************************************************************************************************************************************/

SHOW VARIABLES LIKE 'event_scheduler';
SET GLOBAL event_scheduler = 1;

drop event if exists archivInter;
create event archivInter
on SCHEDULE every 1 hour
starts CURRENT_TIMESTAMP + interval 1 hour
do delete from intervention where etat_intervention = 'terminer';


drop event if exists archivContrat;
create event archivContrat
on SCHEDULE every 1 hour
starts CURRENT_TIMESTAMP + interval 1 hour
do delete from contrat where etat_du_contrat = 'resilier';


drop event if exists archivPassword;
create event archivPassword
on SCHEDULE every 1 hour
starts CURRENT_TIMESTAMP + interval 1 hour
do delete from resetpassword;

/******************************************************************************************* Archivage ***************************************************************************************************/
/********************************************************************************************************************************************************************************************************/

drop table if exists histointervention;
create table histointervention as select *, sysdate() datehisto
from intervention
where 2 = 0;

drop trigger if exists archiintervention;
delimiter //
create trigger archiintervention
after insert on intervention
for each row
begin
insert into histointervention select *, sysdate() from intervention where etat_intervention = 'terminer';
end //
delimiter ;

drop table if exists histocontrat;
create table histocontrat as select *, sysdate() datehisto
from contrat
where 2 = 0;

drop trigger if exists archicontrat;
delimiter //
create trigger archicontrat
before insert on contrat
for each row
begin
insert into histocontrat select *, sysdate() from contrat where etat_du_contrat = 'resilier';
end //
delimiter ;

/************************************************************************** INSERT *****************************************************************************/
/**************************************************************************************************************************************************************/

INSERT INTO client (idclient,nom, siret, tel, email, adresse, CP, ville, role, mdp) VALUES
(null,'Martigue','12356894100054','06.78.19.65.01','agnes@gmail.com','86 Avenue de France','95020','Cergy','userc','123'),
(null,'Durand','12356894100055','06.20.48.23.52','paul@gmail.com','20 Rue de versaille','78013','Versaille','userc','123'),
(null,'Robert','12356894100056','06.12.41.39.11','olivier@gmail.com','7 Rue Pierre Brosolette','92290','Chatenay Malabry','userc','123'),
(null,'Dupont','12356894100053','06.58.79.42.36','maxime@gmail.com','12 Rue de Paris','75012','Paris','userc','123'),
(null,'Petit','12356894100057','06.50.47.96.94','thomas@gmail.com','5 Rue de Paris','75012','Paris','userc','123');

INSERT INTO contrat (num_contrat, idclient, date_souscription, montant_mensuel_ht, etat_du_contrat, objet_du_contrat) VALUES
(null,1,'2010-05-10','113.50','valide','depannage informatique'),
(null,2,'1998-07-15','200.10','resilier','maintenance informatique'),
(null,3,'2001-12-21','107.35','resilier','assistance 24/24'),
(null,4,'2015-01-01','79.99','valide','deplacement 7/7'),
(null,5,'2007-03-14','301.50','valide','depannage informatique');

INSERT INTO intervention (num_intervention, num_contrat, date_heure_affectation, etat_intervention) VALUES
(null,1,'2008-02-13 05:47:15','terminer'),
(null,2,'2000-04-23 02:20:42','en suspend'),
(null,3,'2003-01-07 10:38:20','en suspend'),
(null,4,'2015-10-12 08:40:00','terminer'),
(null,5,'2021-01-01 02:43:10','terminer');


INSERT INTO technicien (idtechnicien, nom, prenom, disponibilite, tarif_horaire, tel, email, role, mdp) VALUES
(null,'Pereira','Philippe','nuit','70.00','06.89.64.62.23','philippe@gmail.com','usert','123'),
(null,'Bousquet','Clement','jour','45.00','06.52.57.59.31','clement@gmail.com','usert','123'),
(null,'Keita','Namake','nuit','65.00','06.74.47.12.19','namake@gmail.com','usert','123'),
(null,'Fakiri','Ahmed','nuit','75.00','06.69.62.24.28','ahmed@gmail.com','usert','123'),
(null,'Leblanc','Alain','jour','50.00','06.48.65.78.10','alain@gmail.com','usert','123');

INSERT INTO planning (idtechnicien, num_intervention, date_heure_debut, date_heure_fin) VALUES
(6,1,'2008-02-13 05:55:15','2008-02-13 06:50:10'),
(7,2,'2000-04-23 04:00:12','2000-04-23 05:35:47'),
(8,3,'2003-01-07 11:38:20','2003-01-07 12:10:05'),
(9,4,'2015-10-12 09:45:00','2015-10-12 10:21:10'),
(10,5,'2021-01-01 02:55:07','2021-01-01 03:43:10');


INSERT INTO user (iduser, nom, prenom, email, mdp, role) VALUES
(null, "Jury","Jury","jury@gmail.com", sha1("jury"), "admin"),
(null, "Chiche","Mehdi","mehdi@gmail.com", sha1("mehdi"), "admin"),
(null, "Li", "Jean-Pierre","jp@gmail.com", sha1("jp"), "admin"),
(null, "Dupont", "alexandre","alexandre@gmail.com", sha1("alexandre"), "userc"),
(null, "Leblanc", "mathias","mathias@gmail.com", sha1("mathias"), "usert");
