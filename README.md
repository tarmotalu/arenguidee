Arenguidee
==========
A project for the [Estonian Development Fund][arengufond] for their
[Arenguidee][arenguidee] idea contest.

This Ruby on Rails app was required to be based on work done for
[Rahvakogu][rahvakogu] ([source code][rahvakogu.git]), which in turn was a fork
of [Social Innovation][social_innovation]. Social Innovation itself was a merge
of [NationBuilder][nationbuilder] by [Jim Gilliam][jim] and [Open Direct
Democracy][odd] by Róbert Viðar Bjarnason and Gunnar Grimsson.

[arengufond]: http://arengufond.ee
[arenguidee]: https://arenguidee.ee
[rahvakogu]: https://www.rahvakogu.ee
[rahvakogu.git]: https://github.com/cenotaph/rahvakogu
[social_innovation]: https://github.com/hinrik/social_innovation
[nationbuilder]: http://www.nationbuilder.com
[odd]: http://github.com/rbjarnason/open-direct-democracy
[jim]: http://www.jimgilliam.com

### ⚠ Beware

If you've ever wanted to see how the [Inner-platform
effect](https://en.wikipedia.org/wiki/Inner-platform_effect) plays out in real
life, you'll be hard put to find a better example. You'll enjoy seeing classes
like `Instance` and `SubInstance` whose properties and behavior are loaded from
the database. Care for a massive translation GUI _framework_ with indecipherable
configuration files keeping your phrases in the database, away from source
control? Good times ahead! Speaking of the database, thinking of creating it
from `schema.rb`?  Well, obviously we're going to need to load all ActiveRecord
models to get `rake db:schema:load` to run...! Oh, but to load the models we're
going to need the database ready with translated phrases, mkay? Cause after all,
what's a little chicken and egg to play Catch-22 with between family.

Even though I tried to save this thing, what I'm saying is that **don't build on
this project**. Ever. Don't try to maintain it and don't let people use it for
new things. **Let it die** the quiet, hopefully agonizing, death it deserves.

Before you leave, though, if you know of others who've used the projects this
was based on, kindly let them know that _all emails_ sent through those apps
were silently copied to <robert@ibuar.is> and <gunnar@ibuar.is.> These two
fellows must have had a hard time reaching inbox zero with all that happening.


Installing
----------
If you want the full Inner-platform to play with, you'll do good to check out
earlier commits — the ones prior to 2014. I've ruined some of the fun by
removing a few Catch-22s.

These days to get it running you'll have to:

1. Get the source code.
2. Run `bundle install`.
3. Run `rake db:create db:schema:load`.
4. Run `rails server`.


License
-------
This and the projects its based on are released under the *Lesser GNU Affero
General Public License*.
