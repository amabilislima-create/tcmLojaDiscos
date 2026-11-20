USE loja_discos;

UPDATE disco SET capa = 'depechemode.jpg' WHERE titulo = N'Depeche Mode';
UPDATE disco SET capa = 'anafrangoeletrico.jpg' WHERE titulo = N'Ana Frango Elétrico';
UPDATE disco SET capa = 'redvelvet.jpg' WHERE titulo = N'Red Velvet';
UPDATE disco SET capa = 'charlixcx.jpg' WHERE titulo = N'Charli XCX';
UPDATE disco SET capa = 'ledzeppelin.jpg' WHERE titulo = N'Led Zeppelin';
UPDATE disco SET capa = 'garotospodres.jpg' WHERE titulo = N'Garotos Podres';
UPDATE disco SET capa = 'aliceinchains.jpg' WHERE titulo = N'Alice in Chains';
UPDATE disco SET capa = 'purejoy.jpg' WHERE titulo = N'Pure Joy';
UPDATE disco SET capa = 'charlieparker.jpg' WHERE titulo = N'Charlie Parker';
UPDATE disco SET capa = 'milesdavis.jpg' WHERE titulo = N'Miles Davis';
UPDATE disco SET capa = 'herbiehancock.jpg' WHERE titulo = N'Herbie Hancock';
UPDATE disco SET capa = 'kennyg.jpg' WHERE titulo = N'Kenny G';
UPDATE disco SET capa = 'antoniovivaldi.jpg' WHERE titulo = N'Antonio Vivaldi';
UPDATE disco SET capa = 'wolfgangamadeusmozart.jpg' WHERE titulo = N'Wolfgang Amadeus Mozart';
UPDATE disco SET capa = 'fredericchopin.jpg' WHERE titulo = N'Frédéric Chopin';
UPDATE disco SET capa = 'philipglass.jpg' WHERE titulo = N'Philip Glass';
UPDATE disco SET capa = 'aliciakeys.jpg' WHERE titulo = N'Alicia Keys';
UPDATE disco SET capa = 'laurynhill.jpg' WHERE titulo = N'Lauryn Hill';
UPDATE disco SET capa = 'frankocean.jpg' WHERE titulo = N'Frank Ocean';
UPDATE disco SET capa = 'timmaia.jpg' WHERE titulo = N'Tim Maia';
UPDATE disco SET capa = 'steviewonder.jpg' WHERE titulo = N'Stevie Wonder';
UPDATE disco SET capa = 'otisredding.jpg' WHERE titulo = N'Otis Redding';
UPDATE disco SET capa = 'thetemptations.jpg' WHERE titulo = N'The Temptations';
UPDATE disco SET capa = 'joaogilberto.jpg' WHERE titulo = N'João Gilberto';
UPDATE disco SET capa = 'osmutantes.jpg' WHERE titulo = N'Os Mutantes';
UPDATE disco SET capa = 'itamarassumpcao.jpg' WHERE titulo = N'Itamar Assumpção';
UPDATE disco SET capa = 'liniker.jpg' WHERE titulo = N'Liniker';
UPDATE disco SET capa = 'adoniranbarbosa.jpg' WHERE titulo = N'Adoniran Barbosa';
UPDATE disco SET capa = 'donaivonelara.jpg' WHERE titulo = N'Dona Ivone Lara';
UPDATE disco SET capa = 'martinhodavila.jpg' WHERE titulo = N'Martinho da Vila';
UPDATE disco SET capa = 'cartola.jpg' WHERE titulo = N'Cartola';

-- Conferir (cada disco deve mostrar o nome do arquivo de imagem):
SELECT titulo, capa FROM disco ORDER BY titulo;
