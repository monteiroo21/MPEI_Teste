movies = readcell('films.txt', 'Delimiter', ',');

%% Gerar o Counting Bloom Filter para os pares (ano, género) dos filmes
% e guardar o Counting Bloom Filter num ficheiro
CBF = runCountingBloomFilter(movies);

%% Save Counting Bloom Filter
save('CBF.mat', 'CBF');


%% Gerar as assinaturas minhash para cada filme baseado nas shingles dos seus títulos
% e guardar as assinaturas minhash num ficheiro na mesma ordem em que os filmes estão
% no ficheiro films.txt
% ===================================================================================

% Criar shingles para os títulos dos filmes
shingles = cell(length(movies), 1);
for i = 1:length(movies)
    shingles{i} = createShingles(movies{i}, 3);
end

k = 100;                                                % Número de funções de hash a usar
titlesShingles = cell(length(movies), 1);
signatures = inf(length(movies), k);
wb = waitbar(0, 'Calculating minhash signatures...');
for i = 1:length(movies)
    if mod(i, 10) == 0
        waitbar(i/length(movies), wb, 'Calculating minhash signatures...');
    end
    titlesShingles{i} = shingles{i};                % Obter os shingles do título do filme
    titlesShingles{i} = lower(titlesShingles{i});   % Meter em minusculas
    titlesShingles{i} = unique(titlesShingles{i});  % Remover duplicados
    for j = 1:length(titlesShingles{i})             % Para cada shingle do nome do filme
        key = titlesShingles{i}{j};                 % Obter o shingle
        minHash = minhash_DJB31MA(key);             % Calcular a assinatura minhash
        signatures(i, :) = min(signatures(i, :), minHash);  % Guardar a assinatura minhash mais pequena
    end
end
close(wb);

% Guardar as assinaturas minhash num ficheiro
save('signaturesTitles.mat', 'signatures');


%% Gerar assinaturas minhash para cada filme baseado nos seus géneros
% e guardar as assinaturas minhash num ficheiro na mesma ordem em que os filmes estão
% no ficheiro films.txt

% ===================================================================================

% Função para verificar se o elemento é diferente de missing
isNotMissing = @(x) ~any(ismissing(x));


genres = unique(movies(:, 3));                               % Obter os géneros
k = 100;                                                % Número de funções de hash a usar
signaturesGenres = inf(length(movies), k);              % Guardar as assinaturas minhash de cada filme
moviesGenres = cell(length(movies), 1);                 % Guardar os géneros de cada filme
wb = waitbar(0, 'Calculating minhash signatures...');
for i = 1:length(movies)                                % Para cada filme
    if mod(i, 10) == 0
        waitbar(i/length(movies), wb, 'Calculating minhash signatures...');
    end
    moviesGenres{i} = movies(i, 3:10);                              % Obter os géneros do filme
    for j = 1:length(moviesGenres{i})                               % Para cada género do filme
        key = moviesGenres{i}{j};                                   % Obter o género
        if ~isNotMissing(key)                                       % Se o género for missing
            continue;                                               % Passar ao próximo género
        end
        minHash = minhash_DJB31MA(key);                             % Calcular a assinatura minhash
        signaturesGenres(i, :) = min(signaturesGenres(i, :), minHash);  % Guardar a assinatura minhash mais pequena
    end
end
close(wb);

save('signaturesGenres.mat', 'signaturesGenres', 'moviesGenres', 'genres');


%% MINHASHING %%

% Create the shingles of a string
% str: the string to create the shingles
% n: the size of the shingles
% return: the shingles of the string
function shingles = createShingles(str, n)
    shingles = cell(1, length(str) - n + 1);
    for i = 1:length(str) - n + 1
        shingles{i} = str(i:i+n-1);
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


%% BLOOM FILTERS %%
function CBF = runCountingBloomFilter(movies)
    tic;
    fprintf("\n========================================================================")
        
    numMovies = height(movies);                         % Number of movies
    genresPerMovie = 3;                                 % Number of genres per movie
    p = 0.01;                                           % Pretended probability of false positives
    numElem = numMovies * genresPerMovie;               % Number of elements to insert in the counting bloom filter
    n = int32(-log(p) * numElem / (log(2)^2));          % Size of ideal bloom filter
    k = int32(n * log(2) / numElem);                    % Number of hash functions

    % 1. Criar um Bloom Filter com n posições e k funções de dispersão
    CBF = CountingBloomFilter(n, k);
    
    fprintf('\n1. Bloom Filter criado com sucesso, com %d funções de dispersão\n', k);

    % 2. Inserir todos pares (ano, género) no Bloom Filter
    wb = waitbar(0, 'Inserindo elementos no Bloom Filter...');
    for i = 1:numMovies
        % Update waitbar every 2500 movies for performance reasons
        if mod(i, 2500) == 0
            waitbar(i/numMovies, wb);
        end
        CBF = CountingBloomFilterInsert(CBF, [num2str(movies{i,2}) movies{i,3}]);
    end
    close(wb);
    fprintf('\n2. Todos os pares (ano, género) inseridos no Bloom Filter\n');

    % 3. Verificar se todos os pares (ano, género) pertencem ao Bloom Filter
    wb = waitbar(0, 'Verificando elementos no Bloom Filter...');
    for i = 1:numMovies
        % Update waitbar every 2500 movies for performance reasons
        if mod(i, 2500) == 0
            waitbar(i/numMovies, wb);
        end
        check = CountingBloomFilterCheck(CBF, [num2str(movies{i,2}) movies{i,3}]);
        if ~check
            fprintf('\n3. Erro: O par (ano, género) (%d, %s) não pertence ao Bloom Filter\n', movies{i,2}, movies{i,3});
            break;
        end
    end
    close(wb);
    fprintf('\n3. Todos os pares (ano, género) verificados no Bloom Filter\n');
    disp(toc);
end

%{
    Criar um Counting Bloom Filter
    input: n - tamanho do Bloom Filter
           k - número de funções de dispersão
    output: CBF - Counting Bloom Filter
%}
function CBF = CountingBloomFilter(n, k)
    CBF.n = n;              % Tamanho do Bloom Filter
    CBF.k = k;              % Número de funções de dispersão
    CBF.cbf = zeros(1, n);   % Inicializar o Bloom Filter
    CBF = CountingBloomFilterInitHF(CBF); % Inicializar as funções de dispersão
end

%{
    Inicializar as funções de dispersão
    input: CBF - Counting Bloom Filter
    output: CBF - Counting Bloom Filter com as funções de dispersão inicializadas
%}
function CBF = CountingBloomFilterInitHF(CBF)
    hashFunctions = {@(element) string2hash(element, 'sdbm'), ...
                    @(element) string2hash(element, 'djb2'), ...
                    @(element) DJB31MA(element, 5381)}; % Utilizei uma seed relativamente grande para evitar colisões 
                                                        % pois não afeta muito o desempenho
    CBF.hashFunctions = cell(1, CBF.k);
    for i = 1:CBF.k
        CBF.hashFunctions{mod(i,3)+1} = @(element) mod(hashFunctions{mod(i,3)+1}(element), CBF.n) + 1;
    end
end

%{
    Inserir um elemento no Bloom Filter
    input: CBF - Counting Bloom Filter
           x - elemento a inserir
    output: CBF - Counting Bloom Filter com o elemento inserido
%}
function CBF = CountingBloomFilterInsert(CBF, x)
    xCell = cell(1, CBF.k);     % Inicializar o array de elementos a inserir
    for i = 1:CBF.k
        xCell{i} = [x num2str(i)];
                                % num2str(i) é o salt para cada função de hashing
                                % Isto assegura que ao repetir o processo para cada função de hashing
                                % repetida, o resultado é diferente, o que ajuda a reduzir a probabilidade de colisões
        % Incrementar o i-ésima posição do Bloom Filter
        index = CBF.hashFunctions{mod(i,3)+1}(xCell{i});
        CBF.cbf(index) = CBF.cbf(index) + 1;
    end
end

%{
    Verificar qual o número de vezes que um elemento x foi inserido no Bloom Filter
    input: CBF - Counting Bloom Filter
           x - elemento a verificar
    output: num - número de vezes que o elemento x foi inserido no Bloom Filter
%}
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

%% Funções de dispersão %%
function hash = string2hash(str,type)
    % This function generates a hash value from a text string
    %
    % hash=string2hash(str,type);
    %
    % inputs,
    %   str : The text string, or array with text strings.
    % outputs,
    %   hash : The hash value, integer value between 0 and 2^32-1
    %   type : Type of has 'djb2' (default) or 'sdbm'
    %
    % From c-code on : http://www.cse.yorku.ca/~oz/hash.html 
    %
    % djb2
    %  this algorithm was first reported by dan bernstein many years ago 
    %  in comp.lang.c
    %
    % sdbm
    %  this algorithm was created for sdbm (a public-domain reimplementation of
    %  ndbm) database library. it was found to do well in scrambling bits, 
    %  causing better distribution of the keys and fewer splits. it also happens
    %  to be a good general hashing function with good distribution.
    %
    % example,
    %
    %  hash=string2hash('hello world');
    %  disp(hash);
    %
    % Function is written by D.Kroon University of Twente (June 2010)
    % From string to double array
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

function h = DJB31MA(chave, seed)
    % implementação da hash function DJB31MA com base no algoritmo obtido
    % no resumo 2014(PJF) que está em C
    %
    %  chave    array de caracteres com a chave
    %  seed     semente que permite obter vários hash codes para a mesma chave
    %
    %  h        hashcode devolvido
    len= length(chave);
    chave= double(chave);
    h= seed;
    for i=1:len
        h = mod(31 * h + chave(i), 2^32 -1) ;
    end
end  