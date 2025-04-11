// lib/features/auth/widgets/onboarding/steps/capability_questionnaire.dart
import 'package:flutter/material.dart';
import '../../../../../shared/theme/app_colors.dart';
import '../../../../../shared/theme/app_text_styles.dart';

class CapabilityQuestion {
  final String question;
  final List<String> options;
  final String? selectedOption;

  CapabilityQuestion({
    required this.question,
    required this.options,
    this.selectedOption,
  });

  CapabilityQuestion copyWith({String? selectedOption}) {
    return CapabilityQuestion(
      question: question,
      options: options,
      selectedOption: selectedOption ?? this.selectedOption,
    );
  }
}

class CapabilityQuestionnaire extends StatefulWidget {
  final List<CapabilityQuestion> initialQuestions;
  final List<String>? existingAnswers;
  final Function(List<Map<String, String?>>) onNext;
  final Function(List<Map<String, String?>>)? onChanged;

  const CapabilityQuestionnaire({
    super.key,
    required this.initialQuestions,
    this.existingAnswers,
    required this.onNext,
    this.onChanged,
  });

  @override
  State<CapabilityQuestionnaire> createState() => _CapabilityQuestionnaireState();
}

class _CapabilityQuestionnaireState extends State<CapabilityQuestionnaire> {
  late List<CapabilityQuestion> _questions;

  @override
  void initState() {
    super.initState();
    
    // Define the default questions
    List<CapabilityQuestion> defaultQuestions = [
      CapabilityQuestion(
        question: 'Can you touch your toes without bending your knees?',
        options: ['Easily', 'With some effort', 'Not even close', 'I prefer not to answer'],
      ),
      CapabilityQuestion(
        question: 'How long could you jog or run without stopping?',
        options: ['I don\'t run', '5-10 minutes', '10-30 minutes', '30-60 minutes', '60+ minutes', 'I prefer not to answer'],
      ),
      CapabilityQuestion(
        question: 'How many push-ups can you do in one go?',
        options: ['None', '1-5', '6-10', '11-20', '20+', 'I prefer not to answer'],
      ),
      CapabilityQuestion(
        question: 'Could you climb a few flights of stairs without getting winded?',
        options: ['Yes, easily', 'Yes, but I\'d be a bit winded', 'I\'d need to take breaks', 'I avoid stairs', 'I prefer not to answer'],
      ),
      CapabilityQuestion(
        question: 'How is your balance? Could you stand on one leg for 30 seconds?',
        options: ['Yes, with no problem', 'Yes, but it\'s wobbly', 'No, I\'d topple over', 'I prefer not to answer'],
      ),
      CapabilityQuestion(
        question: 'When you carry groceries or heavy items, how does it feel?',
        options: ['Easy, no problem', 'Manageable but tiring', 'Difficult, I avoid it', 'I prefer not to answer'],
      ),
      CapabilityQuestion(
        question: 'If you needed to do 20 jumping jacks right now, how would that go?',
        options: ['Piece of cake!', 'I\'d get through it', 'I\'d struggle', 'Not happening', 'I prefer not to answer'],
      ),
    ];
    
    // If initial questions are provided and not empty, use them
    if (widget.initialQuestions.isNotEmpty) {
      _questions = List.from(widget.initialQuestions);
    } else {
      // Otherwise initialize with default questions
      _questions = defaultQuestions;
    }
    
    // Try to restore answers from existing health conditions if available
    if (widget.existingAnswers != null && widget.existingAnswers!.isNotEmpty) {
      for (String answer in widget.existingAnswers!) {
        if (answer.contains(": ")) {
          // Split at the first occurrence of ": " to separate question from answer
          final parts = answer.split(": ");
          if (parts.length >= 2) {
            final questionText = parts[0];
            final answerText = parts.sublist(1).join(": "); // Rejoin in case answer contains ": "
            
            // Find matching question and set its answer
            for (int i = 0; i < _questions.length; i++) {
              if (_questions[i].question == questionText) {
                _questions[i] = _questions[i].copyWith(selectedOption: answerText);
                break;
              }
            }
          }
        }
      }
    }
  }

  void _selectOption(int questionIndex, String option) {
    setState(() {
      _questions[questionIndex] = _questions[questionIndex].copyWith(
        selectedOption: option,
      );
      
      if (widget.onChanged != null) {
        widget.onChanged!(_getQuestionsData());
      }
    });
  }

  List<Map<String, String?>> _getQuestionsData() {
    return _questions.map((q) => {
      'question': q.question,
      'answer': q.selectedOption,
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Your Fitness Capabilities', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            Text(
              'Let\'s get to know your current fitness level with some simple questions.',
              style: AppTextStyles.small,
            ),
            Text(
              'Answer honestly - this helps us personalize your workouts!',
              style: AppTextStyles.small.copyWith(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 16),
            
            // Questions
            ...List.generate(_questions.length, (index) {
              final question = _questions[index];
              return _buildQuestionCard(index, question);
            }),
            
            const SizedBox(height: 16),
            
            // Optional note at the bottom
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.offWhite,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.lightGrey),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Privacy Note:',
                    style: AppTextStyles.small.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your answers help us customize workouts just for you. Feel free to skip any questions you\'re not comfortable with.',
                    style: AppTextStyles.small,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(int index, CapabilityQuestion question) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColors.pink,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    question.question,
                    style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Options
            ...question.options.map((option) {
              final isSelected = question.selectedOption == option;
              return InkWell(
                onTap: () => _selectOption(index, option),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Radio<bool>(
                        value: true,
                        groupValue: isSelected,
                        onChanged: (_) => _selectOption(index, option),
                        activeColor: AppColors.popTurquoise,
                      ),
                      Expanded(
                        child: Text(
                          option,
                          style: AppTextStyles.body.copyWith(
                            color: isSelected ? AppColors.popTurquoise : AppColors.darkGrey,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}