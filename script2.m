load('CBF.mat', 'CBF');
load('signaturesGenres.mat');

%%
movies = readcell('films.txt', 'Delimiter', ',');
numMovies = height(movies);

genres = unique(movies(:,3));

fprintf(['Genres:\t%-16s\t%-8s\t%-10s\t%-10s\n\t\t%-16s\t%-8s\t%-10s\t%-10s' ...
        '\n\t\t%-16s\t%-8s\t%-10s\t%-10s\n\t\t%-16s\t%-8s\t%-10s\t%-10s\n\t' ...
        '\t%-16s\t%-8s\t%-10s\t%-10s\n'], genres{1:20});

genreInput = input("Select a genre: ", "s");
while true
    upperLetter = upper(genreInput(1));
    genreUpper = [upperLetter, genreInput(2:end)];
    if ismember(genreUpper, genres)
        break;
    end
    fprintf('ERROR inputing the genre!\n');
    genreInput = input("Select a genre: ", "s");
end

while true
    disp('-------------------------------------');
    fprintf('SELECTED GENRE: %s\n', genreUpper);
    disp('-------------------------------------');
    fprintf('1 - Change selected Genre\n');
    fprintf('2 - No. of movies of selected Genre on given years\n');
    fprintf('3 - Search movie titles of selected Genre\n');
    fprintf('4 - Search movies based on Genres\n');
    fprintf('5 - Exit\n');
    disp('-------------------------------------');
    option = input('Select an option: ');
    switch(option)
        case 1
            disp('-------------------------------------');
            fprintf(['Genres:\t%-16s\t%-8s\t%-10s\t%-10s\n\t\t%-16s\t%-8s\t%-10s\t%-10s' ...
                    '\n\t\t%-16s\t%-8s\t%-10s\t%-10s\n\t\t%-16s\t%-8s\t%-10s\t%-10s\n\t' ...
                    '\t%-16s\t%-8s\t%-10s\t%-10s\n'], genres{1:20});
            disp('-------------------------------------');
            genreInput = input("Select a genre: ", "s");
            while true
                upperLetter = upper(genreInput(1));
                genreUpper = [upperLetter, genreInput(2:end)];
                if ismember(genreUpper, genres)
                    break;
                end
                fprintf('ERROR inputing the genre!\n');
                genreInput = input("Select a genre: ", "s");
            end
            continue;
        case 2
            years = input("Select a list of years (separated by (',')):","s");
            years = strsplit(years, ',');
            years = str2double(years);
            % Garantir que os anos númericos são válidos
            while true
                if any(isnan(years))
                    fprintf('ERROR inputing the years!\n');
                    years = input("Select a list of years (separated by ('','')):");
                    years = strsplit(years, ',');
                    years = str2double(years);
                else
                    break;
                end
            end

            % Verificar o número estimado de filmes do género selecionado
            for i = 1:length(years)
                year = years(i);
                num = CountingBloomFilterCheck(CBF , [num2str(years(i)) genreInput]);
                fprintf('Number of movies of genre %s in %d: %d\n', genreInput, year, num);
            end
            continue;
        case 3
            movieSearch = input('Insert a string: ', 's');
            k = 1;
            for i = 1:numMovies
                for j = 3:12
                    if strcmp(movies{i, j}, genreUpper)
                        for idx = 1:12
                           moviesbyGenre{k, idx} = movies{i, idx};
                        end
                        k = k + 1;
                    end
                end
            end
            numMoviesGenre = height(moviesbyGenre);
            signatures = getSignatures(moviesbyGenre, 1000);
            minHashSearch = inf(1, 1000);
            shingle = createShingles(movieSearch, 3);
            for j = 1:length(shingle)                         % Para cada shingle do nome do filme
                key = shingle{j};                 % Obter o shingle
                minHash = minhash_DJB31MA(key, 127, 1000);             % Calcular a assinatura minhash
                minHashSearch(1, :) = min(minHashSearch(1, :), minHash);  % Guardar a assinatura minhash mais pequena
            end
            similarities = zeros(1,numMoviesGenre);
            for i = 1:numMoviesGenre
                similarities(i) = (sum(minHashSearch(1, :) == signatures(i,:)) / 1000);
            end
            sortedSimilarities = sort(similarities, 'descend');
            ind = zeros(1, 5);
            for j = 1:5
                for k = 1:numMoviesGenre
                    if (sortedSimilarities(j) == similarities(k))
                        if ~ismember(k, ind)
                            ind(1, j) = k;
                        end
                    end
                end
            end
            for k = 1:5
                for i = 1:length(movies)
                    if strcmp(movies{i,1}, moviesbyGenre{ind(1,k), 1})
                        ind1(k) = i;
                    end
                end
            end
            for j = 1:5
                printInfo(moviesbyGenre, ind(1, j), ind1(1, j), sortedSimilarities(j), 'films.txt');
            end
            continue;
        case 4
            %  Ask for the number of genres to search, it can be none
            userInput = input('Select additional Genres separated by ('','') (press ENTER when no desired additional Genres):  ', 's');
            if isempty(userInput)
                movieGenres = cell(1, 1);
                movieGenres{1} = genreInput;
            else
                % Normalize the input, making the first letter uppercase and the rest lowercase
                upperLetter = upper(userInput(1));
                userInput = [upperLetter, userInput(2:end)];
                % Get the genres from the input
                movieGenres = split(userInput, ',');
                % Check if the input genres are valid
                for i = 1:length(movieGenres)
                    if ~ismember(movieGenres{i}, genres)
                        fprintf('ERROR inputing the genre!\n');
                        movieGenres = genreInput;
                        break;
                    end
                end
                % Add genreInput to the movieGenres and remove duplicates
                movieGenres{end+1} = genreInput;
                movieGenres = unique(movieGenres);
                
            end

            % Create signatures for the selected genres
            selectedSign = inf(1, kMinHash);
            for i = 1:length(movieGenres)                   % For each genre
                key = char(movieGenres(i));                 % Get the genre
                minHash = minhash_DJB31MA(key);             % Create the minhash signature
                selectedSign = min(selectedSign, minHash);  % Get the minimum value for each hash function
            end
            
            % Compare the signatures of the movies with the signatures of the selected genres
            similarity = zeros(numMovies, 1);
            for i = 1:numMovies
                similarity(i) = compareMinHashSignatures(selectedSign, signaturesGenres(i, :));
            end

            % Sort the movies by similarity, then most recent year
            [~, idx] = sortrows([similarity, cell2mat(movies(:, 2))], [-1, -2]);
            
            % Select the top 5 movies
            idx = idx(1:5);
            
            % Print the top 5 movies
            fprintf('\n%-s\t%-40s\t%-16s\t\n', 'Year', 'Movie', 'Similarity');
            for i = 1:length(idx)
                % Print the name, year and similarity of the movie
                fprintf('%-d\t%-40s\t%-.3f\t\n', movies{idx(i), 2}, movies{idx(i), 1}, similarity(idx(i)));
            end
        case 5
            disp('Exiting the program');
            break;
    end
end

function printInfo(movies, k, l, distances, file)
    fileID = fopen(file, 'r');
    C = textscan(fileID, '%s', 'Delimiter', '\n');
    fclose(fileID);
    desiredLine = C{1}{l};
    line = strsplit(desiredLine, ',');
    genresArray = line(3:end);
    genres = strjoin(genresArray, ',');
    fprintf('{%.4f} %s - %s\n', distances, movies{k}, genres);
end

function shingles = createShingles(str, n)
    shingles = cell(1, length(str) - n + 1);
    for i = 1:length(str) - n + 1
        shingles{i} = str(i:i+n-1);
    end
end

function signaturesGenres = getSignaturesGenres(movies, k)
    signaturesGenres = inf(length(movies), k);              % Guardar as assinaturas minhash de cada filme
    moviesGenres = cell(length(movies), 10);                 % Guardar os géneros de cada filme
    wb = waitbar(0, 'Calculating minhash signatures...');
    for i = 1:length(movies)                                % Para cada filme
        if mod(i, 10) == 0
            waitbar(i/length(movies), wb, 'Calculating minhash signatures...');
        end
        moviesGenres{i} = movies(i, 3:12);                              % Obter os géneros do filme
        for j = 1:length(moviesGenres{i})                               % Para cada género do filme
            key = moviesGenres{i}{j};                                   % Obter o género
            key = string(key);
            if ismissing(key)                                           % Se o género for missing
                continue;                                               % Passar ao próximo género
            end
            minHash = minhash_DJB31MA(key, 127, k);                        % Calcular a assinatura minhash
            signaturesGenres(i, :) = min(signaturesGenres(i, :), minHash);  % Guardar a assinatura minhash mais pequena
        end
    end
    close(wb);
end

function jaccardSimilarity = compareMinHashSignatures(sig1, sig2)
    intersection = sum(sig1 == sig2);
    union = numel(unique([sig1, sig2]));
    jaccardSimilarity = intersection / union;
end

function minHash = minhash_DJB31MA(chave, seed, k)
    if nargin < 2
        seed = 127;
        k = 100;
    elseif nargin < 3
        k = 100;
    end

    len = length(chave);
    chave = double(chave);
    
    h = seed;
    for i = 1:len
        h = mod(31 * h + chave(i), 2^32 - 1);
    end
    
    minHash = zeros(1, k);
    
    for j = 1:k
        h = mod(31 * h + j, 2^32 - 1);
        minHash(j) = h;
    end
end

function signatures = getSignatures(movies, k)                                               
    titlesShingles = cell(length(movies), 1);
    signatures = inf(length(movies), k);
    wb = waitbar(0, 'Calculating minhash signatures...');
    for i = 1:length(movies)
        if mod(i, 10) == 0
            waitbar(i/length(movies), wb, 'Calculating minhash signatures...');
        end
        titlesShingles{i} = createShingles(movies{i,1}, 3);         % Obter os shingles do título do filme
        for j = 1:length(titlesShingles{i})                         % Para cada shingle do nome do filme
            key = titlesShingles{i}{j};                 % Obter o shingle
            minHash = minhash_DJB31MA(key, 127, 1000);             % Calcular a assinatura minhash
            signatures(i, :) = min(signatures(i, :), minHash);  % Guardar a assinatura minhash mais pequena
        end
    end
    close(wb);
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

function num = CountingBloomFilterCheck(CBF, x)
    xCell = cell(1, CBF.k);         % Inicializar o array de elementos a inserir
    for i = 1:CBF.k
        xCell{i} = [x num2str(i)];  % Tem de ser o mesmo que foi usado para inserir
        % Verificar o i-ésimo elemento do Bloom Filter
        index = CBF.hashFunctions{mod(i,3)+1}(xCell{i});
        if CBF.cbf(index) == 0
            num = 0;
            return;
        end
        num = CBF.cbf(index);
    end
end