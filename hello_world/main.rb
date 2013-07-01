require 'fuzzystringmatch'
require 'levenshtein'

class Sex
  @allowed = (" ".."~").inject({}){|a,b| a.merge(b => true)}

  def self.breed(word_a, word_b, mrate, arate, drate)
    mutate(crossover(word_a, word_b), mrate, arate, drate)
  end

  def self.crossover(word_a, word_b)
    length = [word_a.size, word_b.size].max
    
    child = []
    (0..(length-1)).to_a.each do |i|
      child << (rand(2).zero? ? word_a[i] : word_b[i])
    end
    child.reject{|l| l.nil?}
  end

  def self.mutate(word, mrate, arate, drate)
    (0..(word.size-1)).to_a.each do |i|
      if rand(1000000) <= mrate*1000000
        new_char = mutate_char(word[i])
        word[i] = new_char if @allowed.include?(new_char)
      end
    end
    if rand(1000000) <= arate*1000000
      r = rand(10)
      if r <= 2
        word << word.first
      elsif r <= 4
        word << word.last
      elsif r <= 6
        word << (rand(127 - 32)+32).chr
      else
        word = duplicate(word)
      end
    end
    if rand(1000000) <= drate*1000000
      word.delete_at(rand(word.size))
    end
    word
  end

  def self.duplicate(word)
    r = rand(10)
    if r <= 2
      word + word
    elsif r <= 4
      word << word[0..rand(word.size)]
    elsif r <= 6
      word[0..rand(word.size)] + word
    else
      word.reverse
    end
  end

  def self.mutate_char(char)
    if rand(10) > 8
      (rand(127 - 32)+32).chr
    else
      new_char = (char.bytes.first + rand(10) - rand(10)).chr
      @allowed.include?(new_char) ? new_char : ''
    end
  rescue
    char
  end
end

class Fitness
  def self.check(word, goal)
    @checker ||= FuzzyStringMatch::JaroWinkler.create( :native )
    word ||= '' #catch nil
    word = word.join('') if word.is_a? Array
    score = @checker.getDistance(word.gsub(/!.+!/,''), goal)
    score# + 0.25 * (goal.size - Levenshtein.distance(word, goal)).to_f / goal.size.to_f
  end

  def p_best(goal)
    puts "#{Fitness.check(goal, goal)} | #{goal}"
  end
end

class Generation
  attr_accessor :size, :mrate, :arate, :drate, :goal, :group, :count
  def initialize(size=20, mrate = 0.1, arate = 0.1, drate = 0.1, goal="abcdefghijklmnopqrstuvwxyz")
    self.size = size
    self.mrate = mrate
    self.arate = arate
    self.drate = drate
    self.goal = goal
    self.count = 0
    self.group = size.times.collect{Sex.breed("", "", mrate, arate, drate)}
  end

  def evolve
    best = @group.collect{|i| [i, Fitness.check(i, goal)]}.sort{|a,b| b.last<=>a.last}[0..(top-1)].collect(&:first)
    new_group = []
    @group.size.times do
      new_group << Sex.breed(best.sample, best.sample, mrate, arate, drate)
    end
    self.count += 1
    @group = new_group
  end

  def p
    best = @group.collect{|i| [i, Fitness.check(i, goal)]}.sort{|a,b| b.last<=>a.last}[0..(top-1)]
    puts "#{count} | #{best[0][1]} | #{@group.collect{|i| i.join('')}.collect{|i| "\"#{i}\""}.join("  ")}"
    puts [size, mrate, arate, drate, goal].join(', ')
  end

  def p_best
    best = @group.collect{|i| [i, Fitness.check(i, goal)]}.sort{|a,b| b.last<=>a.last}[0..(top-1)]
    puts "#{count} | #{best[0][1]} | #{best.collect(&:first).collect{|i| i.join('')}.collect{|i| "\"#{i}\""}.join("  ")}"
  end

  def win?
    @best_possible ||= Fitness.check(goal, goal)
    @group.any?{|i| Fitness.check(i, goal) == @best_possible}
  end

  def top
    10
  end

  def until_win
    until win? do
      evolve
    end
  end

  def self.best_of(size, mrate, arate, drate, goal, count)

    puts count.times.collect{ g=Generation.new(size, mrate, arate, drate, goal); g.until_win; g.count}.inject(&:+) / count.to_f
  end
end

#Generation.best_of(20, 0.02, 0.10, 0.01, "Hello World!!!", 21)
g = Generation.new(30, 0.2, 0.1, 0.1, "Will Lau")
i = 0
until g.win? do
  g.p_best if i % 10 == 0
  i += 1
  g.evolve
end
puts "DONE!"
g.p
