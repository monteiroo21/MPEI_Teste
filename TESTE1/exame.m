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
            continue;
        case 3
            continue;
        case 4
            continue;
        case 5
            disp('Exiting the program');
            break;
    end
end

