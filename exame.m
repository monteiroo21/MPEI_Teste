rest = readcell('restaurantes.txt', 'Delimiter', '\t');
numRest = height(rest);

turistas=load('turistas1.data'); 
t= turistas(1:end,1:2); 
clear turistas;

users = unique(t(:,1));
numUsers = length(users);

Set = restaurantsEvaluated(t);

userID = input('Insert User ID (1 to 836): ');
if userID < 1 || userID > numUsers
    userID = input('The number you gave is invalid. Try again: ');
end

fprintf("1 - Restaurants evaluated by you\n");
fprintf("2 - Set of restaurants evaluated by the most similar user\n");
fprintf("3 - Search Restaurant\n");
fprintf("4 - Find most similar restaurants\n");
fprintf("5 - Estimate the number of evaluations for each restaurant\n");
fprintf("6 - Exit\n");

while true
    userInput = input('Select choice: ');
    if userInput < 1 || userInput > 6
        fprintf('Invalid choice\n');
        continue;
    elseif userInput == 6  % Exit, voltar ao menu principal
        fprintf('Back to main menu\n');
        break;
    end

    switch userInput
        % Restaurants evaluated by you
        case 1
            restaurants = Set{userID};
            n = length(restaurants);
            for i = 1:n
                printInfo(restaurants(i), rest);
            end
            continue;
        % Set of restaurants evaluated by the most similar user
        case 2 
            J = calculateDistances(Set, numUsers, userID);
            [minValue, simUser] = min(J(:, userID));
            restaurants = Set{simUser};
            n = length(restaurants);
            for i = 1:n
                printInfo(restaurants(i), rest);
            end
            continue;
        % Search restaurant
        % TODO: PODEMOS IMPLEMENTAR FILTROS DE BLOOM AQUI 
        case 3
            query = input("Insert restaurant name or ID: ", "s");
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

function Set = restaurantsEvaluated(userData)
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
    
function printInfo(restaurant, rest)
    for i = 1:7
        if ismissing(rest{restaurant, i})
            rest{restaurant, i} = '';
        end
    end
    fprintf('Restaurant ID: %3d - %s | Location: %s, %s | Cuisine: %s | Dishes: %s | Days off: %s\n', rest{restaurant, 1:7});
end

function J = calculateDistances(set, numUsers, userID)
    J=zeros(numUsers);
    tic
    for n2= 1:numUsers
        if n2 ~= userID
            i = intersect(set{userID}, set{n2});
            u = union(set{userID}, set{n2});
            J(n2) = 1 - (length(i)/length(u));
        end
    end
    J(userID, userID) = 1;
    toc
end