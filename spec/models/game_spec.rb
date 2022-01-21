# (c) goodprogrammer.ru

# Стандартный rspec-овский помощник для rails-проекта
require 'rails_helper'

# Наш собственный класс с вспомогательными методами
require 'support/my_spec_helper'

# Тестовый сценарий для модели Игры
#
# В идеале — все методы должны быть покрыты тестами, в этом классе содержится
# ключевая логика игры и значит работы сайта.
RSpec.describe Game, type: :model do
  # Пользователь для создания игр
  let(:user) { FactoryGirl.create(:user) }

  # Игра с прописанными игровыми вопросами
  let(:game_w_questions) do
    FactoryGirl.create(:game_with_questions, user: user)
  end

  let(:wrong_answer_key) { game_w_questions.answer_current_question!('c') }

  # Группа тестов на работу фабрики создания новых игр
  context 'Game Factory' do
    it 'Game.create_game! new correct game' do
      # Генерим 60 вопросов с 4х запасом по полю level, чтобы проверить работу
      # RANDOM при создании игры.
      generate_questions(60)

      game = nil

      # Создaли игру, обернули в блок, на который накладываем проверки
      expect do
        game = Game.create_game_for_user!(user)
        # Проверка: Game.count изменился на 1 (создали в базе 1 игру)
      end.to change(Game, :count).by(1).and(
        # GameQuestion.count +15
        change(GameQuestion, :count).by(15).and(
          # Game.count не должен измениться
          change(Question, :count).by(0)
        )
      )

      # Проверяем статус и поля
      expect(game.user).to eq(user)
      expect(game.status).to eq(:in_progress)

      # Проверяем корректность массива игровых вопросов
      expect(game.game_questions.size).to eq(15)
      expect(game.game_questions.map(&:level)).to eq (0..14).to_a
    end
  end

  # Тесты на основную игровую логику

  context 'game mechanics' do
    it 'should continue game' do
      level = game_w_questions.current_level
      q = game_w_questions.current_game_question
      expect(game_w_questions.status).to eq(:in_progress)

      game_w_questions.answer_current_question!(q.correct_answer_key)

      # Перешли на след. уровень
      expect(game_w_questions.current_level).to eq(level + 1)

      # Ранее текущий вопрос стал предыдущим
      expect(game_w_questions.current_game_question).not_to eq(q)

      # Игра продолжается
      expect(game_w_questions.status).to eq(:in_progress)
      expect(game_w_questions.finished?).to be(false)
    end

    it 'current_game_question' do
      expect(game_w_questions.current_game_question).to eq(game_w_questions.game_questions.first)
    end

    it 'previous_level' do
      #начало игры
      game_w_questions.current_level = 0
      expect(game_w_questions.previous_level).to eq(- 1)
      #в процессе
      game_w_questions.current_level = 10
      expect(game_w_questions.previous_level).to eq(game_w_questions.current_level - 1)
    end
  end

  describe '#answer_current_question!' do
    context 'when answer is wrong' do
      let(:wrong_answer_key) { game_w_questions.answer_current_question!('c') }

      before { game_w_questions.answer_current_question!(wrong_answer_key) }

      it 'should finish game with status fail' do
        expect(wrong_answer_key).to eq(false)
        expect(game_w_questions.status).to eq(:fail)
        expect(game_w_questions.finished?).to be(true)
      end
    end

    context 'when answer is correct' do
      let!(:level) { Question::QUESTION_LEVELS.max }
      let!(:q) { game_w_questions.current_game_question }

      context 'and question is last' do
        before do
          game_w_questions.current_level = level
          game_w_questions.answer_current_question!(q.correct_answer_key)
        end

        it 'should finish game with status won' do
          expect(game_w_questions.status).to eq(:won)
          expect(game_w_questions.finished?).to be(true)
        end

        it 'should assign final prize' do
          expect(game_w_questions.prize).to eq(Game::PRIZES.last)
        end
      end

      context 'and question is not last' do

        before do
          game_w_questions.current_level = 10
          game_w_questions.answer_current_question!(q.correct_answer_key)
        end

        it 'should increase the current level by 1' do
          expect(game_w_questions.current_level).to eq(11)
        end

        it 'should continue game' do
          expect(game_w_questions.status).to eq(:in_progress)
        end
      end

      context 'and time is out ' do

        before { game_w_questions.finished_at = Time.now }

        it 'should finish game with status timeout' do
          game_w_questions.created_at = 36.minutes.ago
          game_w_questions.is_failed = true
          expect(game_w_questions.status).to eq(:timeout)
        end
      end
    end
  end
end
