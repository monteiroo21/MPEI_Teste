
%{
Algoritmos Probabilísticos

Secção para avaliação

Considere uma aplicação, a desenvolver em Matlab, com algumas funcionalidades de um sistema online de disponibilização de informação e sugestão de restaurantes no norte de Portugal. A aplicação deve considerar um conjunto de utilizadores identificados por um ID e um conjunto de restaurantes também identificados por um ID (considerando os IDs definidos por um inteiro positivo).
Dados de entrada:
Considere o ficheiro turistas1.data com as avaliações de cada um 1dos turistas relativamente aos restaurantes que visitou. Utilize os dados das duas primeiras colunas desse ficheiro para identificar os turistas (coluna 1) e os restaurantes que cada utilizador avaliou (coluna 2), a coluna 3 contém a score atribuída ao restaurante. Utilize, também, o ficheiro restaurantes.txt, com os seguintes campos: ID, Nome, Localidade, Concelho, Tipo de cozinha, Pratos recomendados, Dias de descanso (separados por tabs). A linha n contém a informação do restaurante com o ID n usado na segunda coluna do ficheiro turistas1.data.
NOTA: executando no Matlab a instrução
rest = readcell('restaurantes.txt', 'Delimiter', '\t');
é criado o cell array rest, em que a célula rest{i,j} contém a informação da linha i e da coluna j do ficheiro restaurantes.txt.

Descrição da aplicação a desenvolver:
A aplicação deve começar por pedir o ID de utilizador que se torna o utilizador actual:
    Insert User ID (1 to ??):
certificando-se que o número introduzido é um ID válido (no ficheiro turistas1.data, os IDs dos utilizadores são números inteiros desde 1 até ao número de utilizadores distintos). Em seguida, a aplicação deve permitir ao utilizador seleccionar uma de 6 opções:
1 - Restaurants evaluated by you
2 - Set of restaurants evaluated by the most similar user
3 - Search restaurant
4 - Find most similar restaurants
5 - Estimate the number of evaluations for each restaurant
6 - Exit
Select choice:
%}

%% ----------------- Leitura dos dados -----------------
clc;

% UserID;Restaurante;Score
turistas_data = load('turistas1.data');
% ID;Nome;Localidade;Concelho;Tipo de cozinha;Pratos recomendados;Dias de descanso
rest_data = readcell('restaurantes.txt', 'Delimiter', '\t');    

% Lista de utilizadores
usersSet = buildRestaurantListForEachUser(turistas_data);
N_users = length(usersSet);   % Número de utilizadores

% Lista de restaurantes e respetivos dados
restaurants = unique(turistas_data(:,2));   % Fica com os IDs dos restaurantes
N_restaurants = length(restaurants);        % Número de restaurantes
restaurants_data = cell(N_restaurants, 7);  % Inicializa a lista de restaurantes

% Índices dos campos, para facilitar a leitura
[restID, restName, restLoc, restConc, restCuisine, restDishes, restDays] = deal(1, 2, 3, 4, 5, 6, 7);
for n = 1:N_restaurants                    % Para cada restaurante
    ind = turistas_data(:,2) == restaurants(n);     % Índices dos restaurantes avaliados pelo utilizador n
    restaurants_data{n, restID} = restaurants(n);   % ID do restaurante
    restaurants_data{n, restName} = rest_data{restaurants(n), 2};   % Nome do restaurante
    restaurants_data{n, restLoc} = rest_data{restaurants(n), 3};    % Localidade
    restaurants_data{n, restConc} = rest_data{restaurants(n), 4};   % Concelho
    restaurants_data{n, restCuisine} = rest_data{restaurants(n), 5};% Tipo de cozinha
    restaurants_data{n, restDishes} = rest_data{restaurants(n), 6}; % Pratos recomendados
    restaurants_data{n, restDays} = rest_data{restaurants(n), 7};   % Dias de descanso
end


%% ----------------- Pré-processamento -----------------
%% Calcular as distâncias de Jaccard entre todos os utilizadores
% Método naive
tic;
JU_naive = calculateJaccardDistancesUsers(usersSet);  % Matriz de distâncias de Jaccard
disp("Time to calculate Jaccard distances (naive): " + toc + " seconds");

%% Método MinHash
% Calcular as assinaturas minhash de cada utilizador
seed = 127; % Seed para o gerador de números aleatórios
k = 1000;    % Número de funções de hash
tic;
signatures = inf(N_users, k);
for n = 1 : N_users                                         % Para cada utilizador n
    user_list = turistas_data(turistas_data(:, 1) == n, 2); % Lista de restaurantes avaliados pelo utilizador n
    for i = 1 : size(user_list, 1)                          % Para cada restaurante avaliado pelo utilizador n
        key = num2str(user_list(i, 1));                     % Chave para o minhash
        minHash = minhash_DJB31MA(key, seed, k);            % Calcular a assinatura minhash
        signatures(n, :) = min(signatures(n, :), minHash);  % Guardar a assinatura minhash mais pequena
    end
end
% Calcular as distâncias de Jaccard entre todos os utilizadores
JU_minhash = zeros(N_users);                                 % Inicializa a matriz de distâncias de Jaccard
for n1 = 1 : N_users                                        % Para cada utilizador n1
    for n2 = n1+1 : N_users                                 % Compara com os utilizadores seguintes
        JU_minhash(n1, n2) = sum(signatures(n1, :) ... 
                                == signatures(n2, :)) / k;  % Calcula a distância de Jaccard entre n1 e n2
        JU_minhash(n2, n1) = JU_minhash(n1, n2);              % A matriz é simétrica
    end
end
disp("")
disp("Time to calculate Jaccard distances (MinHash): " + toc + " seconds");


% Diferença entre os dois métodos
disp("Diferença entre os dois métodos: " + sum(JU_naive(:) - JU_minhash(:)) / (N_users * (N_users - 1) / 2) + " valor de k: " + k);
% Desvio padrão das diferenças
disp("Desvio padrão das diferenças: " + std(JU_naive(:) - JU_minhash(:)));


%% Calcular restaurantes mais similares
% Método naive
tic;
JR_naive = calculateJaccardDistancesRest(restaurants_data(:, [restLoc, restConc, restCuisine, restDishes, restDays])');
disp("Time to calculate most similar users (naive): " + toc + " seconds");

% Método MinHash
% Calcular as assinaturas minhash de cada restaurante
restSet = restaurants_data(:, [restLoc, restConc, restCuisine, restDishes, restDays]);
seed = 127; % Seed para o gerador de números aleatórios
k = 1000;    % Número de funções de hash
tic;
signatures = inf(N_restaurants, k);
for n = 1 : N_restaurants                                         % Para cada restaurante n
    rest_list = restSet{n};                                       % Lista de restaurantes avaliados pelo restaurante n
    for i = 1 : size(rest_list, 1)                                % Para cada restaurante avaliado pelo restaurante n
        key = num2str(rest_list(i, 1));                           % Chave para o minhash
        minHash = minhash_DJB31MA(key, seed, k);                  % Calcular a assinatura minhash
        signatures(n, :) = min(signatures(n, :), minHash);        % Guardar a assinatura minhash mais pequena
    end
end
% Calcular as distâncias de Jaccard entre todos os restaurantes
JR_minhash = zeros(N_restaurants);                                 % Inicializa a matriz de distâncias de Jaccard
for n1 = 1 : N_restaurants                                        % Para cada restaurante n1
    for n2 = n1+1 : N_restaurants                                 % Compara com os restaurantes seguintes
        JR_minhash(n1, n2) = sum(signatures(n1, :) ... 
                                == signatures(n2, :)) / k;         % Calcula a distância de Jaccard entre n1 e n2
        JR_minhash(n2, n1) = JR_minhash(n1, n2);                     % A matriz é simétrica
    end
end
disp("")
disp("Time to calculate most similar users (MinHash): " + toc + " seconds");



% Guardar os dados para não ter de os calcular novamente
save('data.mat', 'JU_naive', 'JU_minhash', 'signatures', 'usersSet', 'restaurants', 'N_users', 'N_restaurants', 'restaurants_data', 'JR_naive', 'JR_minhash', 'restSet');



%% ----------------- Aplicação -----------------
load('data.mat');

    searched_restaurant = 0;   % ID do restaurante pesquisado

    % Correr com o utilizador atual


        switch choice
            % Restaurants evaluated by you
            case 1
                % Lista de restaurantes avaliados pelo utilizador atual
                restaurants = usersSet{user_id};
                % Mostrar os restaurantes
                printRestaurants(restaurants_data(restaurants, :));
            
                continue;

            % Set of restaurants evaluated by the most similar user
            case 2  
                
                % Método naive
                [max_sim, user_sim] = max(JU_naive(user_id, :));
                restaurants = usersSet{user_sim};
                fprintf('Most similar user (naive): %d - Similarity: %f\n', user_sim, max_sim);
                printRestaurants(restaurants_data(restaurants, :));

                % Método MinHash
                [max_sim, user_sim] = max(JU_minhash(user_id, :));
                restaurants = usersSet{user_sim};
                fprintf('Most similar user (minhash): %d - Estimated Similarity: %f\n', user_sim, max_sim);
                printRestaurants(restaurants_data(restaurants, :));


            continue;

            % Search restaurant
            % TODO: PODEMOS IMPLEMENTAR FILTROS DE BLOOM AQUI 
            case 3
                
                prompt = sprintf("Insert restaurant name or ID: ");
                query = input(prompt, "s");
                restaurant_id = str2double(query);
                
                if isnan(restaurant_id)  % Se não for um número
                    % Procurar o restaurante pelo nome
                    restaurant_id = find(strcmp(restaurants_data(:, restName), query));
                    if isempty(restaurant_id)
                        fprintf('Restaurant not found\n');
                        continue;
                    end
                else
                    % Procurar o restaurante pelo ID
                    if restaurant_id < 1 || restaurant_id > N_restaurants
                        fprintf('Invalid restaurant ID\n');
                        continue;
                    end
                end

                % Mostrar os dados do restaurante
                fprintf('Restaurant ID: %d - %s\n', restaurants_data{restaurant_id, restID:restName});
                fprintf('Location: %s, %s\n', restaurants_data{restaurant_id, restLoc:restConc});
                fprintf('Cuisine: %s\n', restaurants_data{restaurant_id, restCuisine});
                fprintf('Dishes: %s\n', restaurants_data{restaurant_id, restDishes});
                fprintf('Days off: %s\n', restaurants_data{restaurant_id, restDays});

                % Mostrar se o utilizador atual avaliou o restaurante
                if ismember(restaurant_id, usersSet{user_id})
                    fprintf('Your score: %d\n', turistas_data(turistas_data(:, 1) == user_id & turistas_data(:, 2) == restaurant_id, 3));
                else
                    fprintf('You have not evaluated this restaurant\n');
                end

                searched_restaurant = restaurant_id;

                continue;
        

                % Find most similar restaurants
            case 4
                % Restaurantes mais similares aos avaliados pelo utilizador atual
                % Método naive
                % Lista de restaurantes avaliados pelo utilizador atual
                restaurants = cell2mat(restaurants_data(usersSet{user_id}));
                
                % Comparar com todos os restaurantes
                for index = 1:length(restaurants)
                    % Calcular a distância de Jaccard entre n e todos os restaurantes
                    min_dist = inf;
                    rest_dist = 0;
                    for m = 1:N_restaurants
                        % Se o restaurante já foi avaliado pelo utilizador atual, ignorar
                        if ismember(m, restaurants)
                            continue;
                        end
                        sim = JR_naive(restaurants(index), m);
                        if sim < min_dist
                            min_dist = sim;
                            rest_dist = m;
                        end 
                    end
                    fprintf('Most similar restaurant (naive): %d - Similarity: %f\n', rest_dist, 1-min_dist);
                    printRestaurants(restaurants_data([restaurants(index), rest_dist], :));
                end
                



                continue;
    
            % Estimate the number of evaluations for each restaurant
            case 5

                continue;
        end
    end
end







%{
    Função para calcular a assinatura minhash de uma chave
    input:
        chave: string   -> chave a calcular a assinatura minhash
        seed: inteiro   -> seed para o gerador de números aleatórios
        k: inteiro      -> número de funções de hash a usar
    output:
        minHash: vetor  -> vetor com a assinatura minhash da chave
%}
function minHash = minhash_DJB31MA(chave, seed, k)
    len = length(chave);
    chave = double(chave);
    
    h = seed;
    for i = 1:len
        h = mod(31 * h + chave(i), 2^32 - 1);
    end
    
    minHash = zeros(1, k);
    
    for j = 1:k
        h = mod(31 * h + j + 0.1, 2^32 - 1); % Adiciona 0.1 para evitar zero
        minHash(j) = h;
    end
end


%{
    Função para calcular as distâncias de Jaccard entre todos os utilizadores
    input:
        Set: cell array -> Set de avaliações de cada utilizador
    output:
        J: matriz       -> Matriz de distâncias de Jaccard
%}
function J = calculateJaccardDistancesUsers(Set)
    Nu = length(Set);   % Número de utilizadores
    J = zeros(Nu);      % Inicializa a matriz de distâncias de Jaccard

    wb = waitbar(0, 'Calculando distâncias de Jaccard');
    for n1 = 1:Nu                                       % Para cada utilizador
        if mod(n1, 100) == 0
            wb = waitbar(n1/Nu, wb, sprintf('Calculando Distâncias de Jaccard - Utilizador %d/%d', n1, Nu));
        end

        for n2 = n1+1:Nu                                % Compara com os utilizadores seguintes
            % Calcular a distância de Jaccard entre n1 e n2
            intersection_size = length(intersect( Set{n1},  Set{n2} ));
            union_size = length(union( Set{n1},  Set{n2} ));
            J(n1, n2) = intersection_size / union_size;

            % A matriz é simétrica
            J(n2, n1) = J(n1, n2);
        end
    end
    delete(wb);
end

function J = calculateJaccardDistancesRest(Set)
    Nu = size(Set, 2);   % Número de restaurantes
    J = zeros(Nu);      % Inicializa a matriz de distâncias de Jaccard

    wb = waitbar(0, 'Calculando distâncias de Jaccard');
    for n1 = 1:Nu                                       % Para cada restaurante
        if mod(n1, 100) == 0
            wb = waitbar(n1/Nu, wb, sprintf('Calculando Distâncias de Jaccard - Restaurante %d/%d', n1, Nu));
        end

        for n2 = n1+1:Nu                                % Compara com os restaurantes seguintes
            % Calcular a distância de Jaccard entre n1 e n2
            intersection_size = length(intersect( Set(:, n1),  Set(:, n2) ));
            union_size = length(union( Set(:, n1),  Set(:, n2) ));
            J(n1, n2) = 1 - intersection_size / union_size;

            % A matriz é simétrica
            J(n2, n1) = J(n1, n2);
        end
    end
    delete(wb);
end


%{
    Função para construir a lista de restaurantes para cada utilizador
    input:
        userData: matriz    -> Matriz com os dados dos utilizadores
    output:
        Set: cell array     -> Set de avaliações de cada utilizador
%}
function Set = buildRestaurantListForEachUser(userData)
    % Lista de utilizadores
    users = unique(userData(:,1));      % Fica com os IDs dos utilizadores
    Nu = length(users);                 % Número de utilizadores

    % Lista de restaurantes para cada utilizador
    Set = cell(Nu, 1);                          % Inicializa a lista de restaurantes para cada utilizador
    for n = 1:Nu                                % Para cada utilizador
        ind = userData(:,1) == users(n);        % Índices dos restaurantes avaliados pelo utilizador n
        Set{n} = [Set{n} userData(ind,2)];      % Adiciona os restaurantes avaliados pelo utilizador n
    end
end


%{
    Função para imprimir os restaurantes
    input:
        restData: cell array -> Cell array com os dados dos restaurantes
%}
function printRestaurants(restData)
    for n = 1:size(restData, 1)
        fprintf('Restaurant ID: %3d - %20s | Location: %20s, %12s | Cuisine: %15s | Dishes: %30s | Days off: %8s\n', restData{n, 1:7});
    end
end
