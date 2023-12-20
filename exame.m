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
                printInfo1(restaurants(i), rest);
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
        case 3
            restaurant = input("Write a string: ", "s");
            distances = zeros(numRest);
            for i = 1:numRest
                distances(i) = calculateDistancesShingles(restaurant, rest{i, 2});
            end
            sortedDistances = sort(distances);
            ind = zeros(5);
            for j = 1:5
                for k = 1:numRest
                    if (sortedDistances(j) == distances(k))
                        ind(j) = k;
                    end
                end
            end
            num = 0;
            for k = 1:5
                if distances(ind(k)) <= 0.99
                    printInfo(ind(k), rest);
                    num = num + 1;
                end
            end
            if num == 0
                fprintf('Restaurant not found\n');
            end
            continue;
        case 4
            restaurants = Set{userID};
            n = length(restaurants);
            for i = 1:n
                printInfo1(restaurants(i), rest);
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

function printInfo1(restaurant, rest)
    fprintf('Restaurant ID: %3d - %s | Location: %s\n', rest{restaurant, 1:2}, rest{restaurant, 4});
end

function J = calculateDistances(set, numUsers, userID)
    J=zeros(numUsers);
    tic
    for n2= 1:numUsers
        if n2 ~= userID
            i = intersect(set{userID}, set{n2});
            u = union(set{userID}, set{n2});
            J(n2, userID) = 1 - (length(i)/length(u));
        end
    end
    J(userID, userID) = 1;
    toc
end

function h= DJB31MA( chave, seed)
    len= length(chave);
    chave= double(chave);
    h= seed;
    for i=1:len
        h = mod(31 * h + chave(i), 2^32 -1);
    end
end

function hash=string2hash(str,type)
    str=double(str);
    if(nargin<2), type='djb2'; end
    switch(type)
        case 'djb2'
            hash = 5381*ones(size(str,1),1); 
            for i=1:size(str,2)
                hash = mod(hash * 33 + str(:,i), 2^32-1); 
            end
        case 'sdbm'
            hash = zeros(size(str,1),1);
            for i=1:size(str,2)
                hash = mod(hash * 65599 + str(:,i), 2^32-1);
            end
        otherwise
            error('string_hash:inputs','unknown type');
    end
end

function shingles = createShingles(str, n)
    shingles = cell(1, length(str) - n + 1);
    for i = 1:length(str) - n + 1
        shingles{i} = str(i:i+n-1);
    end
end

function distance = calculateDistancesShingles(str1, str2)
    set1 = unique(createShingles(str1, 5));
    set2 = unique(createShingles(str2, 5));
    i = intersect(set1, set2);
    u = union(set1, set2);
    distance = 1 - (length(i)/length(u));
end