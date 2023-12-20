% Parâmetros
num_turistas = 500;
num_restaurantes = 100;
num_avaliacoes = 3000;

lista_avaliacoes = zeros(num_avaliacoes, 3);
% Gera uma avaliação para cada turista
for i = 1:num_turistas
    % Gera uma avaliação aleatória
    avaliacao = [i, randi(num_restaurantes), randi(5)];
    lista_avaliacoes(i, :) = avaliacao;
end

% Gera lista de avaliações até que se tenha 200 avaliações válidas
count = i;
while true
    % Gera outra avaliação aleatória
    avaliacao = [randi(num_turistas), randi(num_restaurantes), randi(5)];
    % Verifica se não existe uma avaliação do mesmo turista para o mesmo restaurante
    if ~ismember(avaliacao(1:2), lista_avaliacoes(:, 1:2), 'rows')
        % Se não existir, adiciona à lista de avaliações
        count = count + 1;
        lista_avaliacoes(count, :) = avaliacao;
    end
    % Se já existirem 200 avaliações, termina
    if count == num_avaliacoes
        break
    end
end

% Verifica se cada avaliação é única vendo se as priemiras duas colunas são únicas
assert(size(unique(lista_avaliacoes(:, 1:2), 'rows'), 1));


% Guardar no ficheiro turistas1.data
fid = fopen('turistas1.data', 'w');
fprintf(fid, '%d %d %d\n', lista_avaliacoes');
fclose(fid);


%% Gerar dados para o ficheiro restaurantes.txt
% Campos: ID, Nome, Localidade, Concelho, Tipo de cozinha, Pratos recomendados, Dias de descanso (separados por tabs).
% A linha n contém a informação do restaurante com o ID n usado na segunda coluna do ficheiro turistas1.data.

% Parâmetros
num_restaurantes = 100;
pratos = ["Lasanha", "Sushi", "Pad Thai", "Hambúrguer Clássico", "Paella", "Churrasco", "Curry de Frango", "Tacos Mexicanos", "Ramen", "Moussaka", "Ceviche", "Fondue de Queijo", "Falafel", "Pho", "Sopa de Tomate com Manjericão"];
cozinhas = ["Italiana"; "Japonesa"; "Tailandesa"; "Americana"; "Espanhola"; "Brasileira"; "Indiana"; "Mexicana"; "Japonesa"; "Grega"; "Peruana"; "Suíça"; "Médio Oriente"; "Vietnamita"; "Francesa"];
concelhos = ["Lisboa"; "Porto"; "Coimbra"; "Faro"; "Braga"; "Aveiro"; "Évora"; "Funchal"; "Viseu"; "Leiria"];
% Localidades de cada concelho
localidades = ["Almada", "Vila Nova de Gaia", "Santa Clara", "Olhão", "São Victor", "Esgueira", "São Sebastião da Giesteira", "São Martinho", "Abraveses", "São Pedro"];
% Dias de descanso de cada restaurante
dias_descanso = ["Domingo"; "Segunda"; "Terça"; "Quarta"; "Quinta"; "Sexta"; "Sábado"];

% Gera uma avaliação para cada turista
lista_restaurantes = cell(num_restaurantes, 7);
for i = 1:num_restaurantes
    % Gera uma avaliação aleatória
    restaurante = {i, sprintf("Restaurante %d", i), localidades(randi(size(localidades, 1))), concelhos(randi(size(concelhos, 1))), cozinhas(randi(size(cozinhas, 1))), pratos(randi(size(pratos, 1))), dias_descanso(randi(size(dias_descanso, 1)))};
    lista_restaurantes(i, :) = restaurante;
end

% Guardar no ficheiro restaurantes.txt
fid = fopen('restaurantes.txt', 'w');
for i = 1:num_restaurantes
    % Gera uma avaliação aleatória
    restaurante = {i, sprintf("Restaurante_%d", i), localidades(randi(length(localidades))), concelhos(randi(length(concelhos))), cozinhas(randi(length(cozinhas))), pratos(randi(length(pratos))), dias_descanso(randi(length(dias_descanso)))};
    lista_restaurantes(i, :) = restaurante;
    
    % Imprime os dados no arquivo
    fprintf(fid, '%d\t%s\t%s\t%s\t%s\t%s\t%s\n', restaurante{1}, restaurante{2}, restaurante{3}, restaurante{4}, restaurante{5}, restaurante{6}, restaurante{7});
end
fclose(fid);