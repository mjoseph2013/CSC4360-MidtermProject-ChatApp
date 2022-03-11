import "package:flutter_rating_bar/flutter_rating_bar.dart";
import "package:flutter/material.dart";

class RateStar extends StatefulWidget {
  const RateStar({Key? key}) : super(key: key);

  @override
  State<RateStar> createState() => _RateStarState();
}

//how to get rating to not change after selected by user, maybe used message id
class _RateStarState extends State<RateStar> {
  @override
  Widget build(BuildContext context) {
    return RatingBar.builder(
      initialRating: 2.5, //avg user rating
      minRating: 0,
      direction: Axis.horizontal,
      allowHalfRating: true,
      itemCount: 5,
      itemPadding: const EdgeInsets.symmetric(horizontal: 1.0),
      itemBuilder: (context, _) => const Icon(
        Icons.star,
        color: Colors.amber,
      ),
      onRatingUpdate: (rating) {
        print(rating);
        //update user rating field in databse by averaging all ratings
        //post user's avg rating in search field w/ name & email
      },
    );
  }
}
